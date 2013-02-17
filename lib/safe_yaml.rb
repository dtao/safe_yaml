require "yaml"
require "safe_yaml/transform/to_boolean"
require "safe_yaml/transform/to_date"
require "safe_yaml/transform/to_float"
require "safe_yaml/transform/to_integer"
require "safe_yaml/transform/to_nil"
require "safe_yaml/transform/to_symbol"
require "safe_yaml/transform/to_time"
require "safe_yaml/transform"
require "safe_yaml/resolver"

module SafeYAML
  MULTI_ARGUMENT_YAML_LOAD = YAML.method(:load).arity != 1
  YAML_ENGINE = defined?(YAML::ENGINE) ? YAML::ENGINE.yamler : "syck"

  DEFAULT_OPTIONS = {
    :default_mode         => nil,
    :deserialize_symbols  => false,
    :whitelisted_tags     => [],
    :custom_initializers  => {},
    :raise_on_unknown_tag => false
  }.freeze

  OPTIONS = DEFAULT_OPTIONS.dup

  module_function
  def restore_defaults!
    OPTIONS.clear.merge!(DEFAULT_OPTIONS)
  end

  def tag_safety_check!(tag)
    return if tag.nil?
    if OPTIONS[:raise_on_unknown_tag] && !OPTIONS[:whitelisted_tags].include?(tag) && !tag_is_explicitly_trusted?(tag)
      raise "Unknown YAML tag '#{tag}'"
    end
  end

  if YAML_ENGINE == "psych"
    def tag_is_explicitly_trusted?(tag)
      false
    end

  else
    TRUSTED_TAGS = ["tag:yaml.org,2002:str"].freeze

    def tag_is_explicitly_trusted?(tag)
      TRUSTED_TAGS.include?(tag)
    end
  end
end

module YAML
  def self.load_with_options(yaml, *filename_and_options)
    options   = filename_and_options.last || {}
    safe_mode = safe_mode_from_options("load", options)
    arguments = [yaml]
    arguments << filename_and_options.first if SafeYAML::MULTI_ARGUMENT_YAML_LOAD
    safe_mode == :safe ? safe_load(*arguments) : unsafe_load(*arguments)
  end

  def self.load_file_with_options(file, options={})
    safe_mode = safe_mode_from_options("load_file", options)
    safe_mode == :safe ? safe_load_file(file) : unsafe_load_file(file)
  end

  if SafeYAML::YAML_ENGINE == "psych"
    require "safe_yaml/safe_to_ruby_visitor"
    require "safe_yaml/psych_resolver"
    def self.safe_load(yaml, filename=nil)
      safe_resolver = SafeYAML::PsychResolver.new
      tree = if SafeYAML::MULTI_ARGUMENT_YAML_LOAD
        Psych.parse(yaml, filename)
      else
        Psych.parse(yaml)
      end
      return safe_resolver.resolve_node(tree)
    end

    def self.safe_load_file(filename)
      File.open(filename, 'r:bom|utf-8') { |f| self.safe_load f, filename }
    end

    def self.unsafe_load_file(filename)
      if SafeYAML::MULTI_ARGUMENT_YAML_LOAD
        # https://github.com/tenderlove/psych/blob/v1.3.2/lib/psych.rb#L296-298
        File.open(filename, 'r:bom|utf-8') { |f| self.unsafe_load f, filename }
      else
        # https://github.com/tenderlove/psych/blob/v1.2.2/lib/psych.rb#L231-233
        self.unsafe_load File.open(filename)
      end
    end

  else
    require "safe_yaml/syck_resolver"
    require "safe_yaml/syck_node_monkeypatch"

    def self.safe_load(yaml)
      resolver = SafeYAML::SyckResolver.new
      tree = YAML.parse(yaml)
      return resolver.resolve_node(tree)
    end

    def self.safe_load_file(filename)
      File.open(filename) { |f| self.safe_load f }
    end

    def self.unsafe_load_file(filename)
      # https://github.com/indeyets/syck/blob/master/ext/ruby/lib/yaml.rb#L133-135
      File.open(filename) { |f| self.unsafe_load f }
    end
  end

  class << self
    alias_method :unsafe_load, :load
    alias_method :load, :load_with_options
    alias_method :load_file, :load_file_with_options

    def enable_symbol_parsing?
      warn_of_deprecated_method("set the SafeYAML::OPTIONS[:deserialize_symbols] option instead")
      SafeYAML::OPTIONS[:deserialize_symbols]
    end

    def enable_symbol_parsing!
      warn_of_deprecated_method("set the SafeYAML::OPTIONS[:deserialize_symbols] option instead")
      SafeYAML::OPTIONS[:deserialize_symbols] = true
    end

    def disable_symbol_parsing!
      warn_of_deprecated_method("set the SafeYAML::OPTIONS[:deserialize_symbols] option instead")
      SafeYAML::OPTIONS[:deserialize_symbols] = false
    end

    def enable_arbitrary_object_deserialization?
      warn_of_deprecated_method("set the SafeYAML::OPTIONS[:default_mode] to either :safe or :unsafe")
      SafeYAML::OPTIONS[:default_mode] == :unsafe
    end

    def enable_arbitrary_object_deserialization!
      warn_of_deprecated_method("set the SafeYAML::OPTIONS[:default_mode] to either :safe or :unsafe")
      SafeYAML::OPTIONS[:default_mode] = :unsafe
    end

    def disable_arbitrary_object_deserialization!
      warn_of_deprecated_method("set the SafeYAML::OPTIONS[:default_mode] to either :safe or :unsafe")
      SafeYAML::OPTIONS[:default_mode] = :safe
    end

    private
    def safe_mode_from_options(method, options={})
      if options[:safe].nil?
        safe_mode = SafeYAML::OPTIONS[:default_mode] || :safe
        Kernel.warn "Called '#{method}' without the :safe option -- defaulting to #{safe_mode} mode." if SafeYAML::OPTIONS[:default_mode].nil?
        return safe_mode
      end

      options[:safe] ? :safe : :unsafe
    end

    def warn_of_deprecated_method(message)
      method = caller.first[/`([^']*)'$/, 1]
      Kernel.warn("The method 'YAML.#{method}' is deprecated and will be removed in the next release of SafeYAML -- #{message}.")
    end
  end
end
