require "yaml"
require "safe_yaml/transform/to_boolean"
require "safe_yaml/transform/to_date"
require "safe_yaml/transform/to_float"
require "safe_yaml/transform/to_integer"
require "safe_yaml/transform/to_nil"
require "safe_yaml/transform/to_symbol"
require "safe_yaml/transform/to_time"
require "safe_yaml/transform"
require "safe_yaml/version"

module SafeYAML
  OPTIONS = {
    :enable_symbol_parsing => false,
    :enable_arbitrary_object_deserialization => false
  }
end

module YAML
  def self.load_with_options(yaml, options={})
    safe_mode = safe_mode_from_options("load", options)

    arguments = [yaml]
    if RUBY_VERSION >= "1.9.3"
      arguments << options[:filename]
    end

    safe_mode ? safe_load(*arguments) : unsafe_load(*arguments)
  end

  def self.load_file_with_options(file, options={})
    safe_mode = safe_mode_from_options("load_file", options)
    safe_mode ? safe_load_file(file) : unsafe_load_file(file)
  end

  def self.load_with_filename_and_options(yaml, filename=nil, options={})
    load_with_options(yaml, options.merge(:filename => filename))
  end

  if RUBY_VERSION >= "1.9.3"
    require "safe_yaml/psych_handler"
    def self.safe_load(yaml, filename=nil)
      safe_handler = SafeYAML::PsychHandler.new
      Psych::Parser.new(safe_handler).parse(yaml, filename)
      return safe_handler.result
    end

    def self.safe_load_file(filename)
      File.open(filename, 'r:bom|utf-8') { |f| self.safe_load f, filename }
    end

    def self.unsafe_load_file(filename)
      # https://github.com/tenderlove/psych/blob/v1.3.2/lib/psych.rb#L296-298
      File.open(filename, 'r:bom|utf-8') { |f| self.unsafe_load f, filename }
    end

  elsif RUBY_VERSION == "1.9.2"
    require "safe_yaml/psych_handler"
    def self.safe_load(yaml)
      safe_handler = SafeYAML::PsychHandler.new
      Psych::Parser.new(safe_handler).parse(yaml)
      return safe_handler.result
    end

    def self.safe_load_file(filename)
      File.open(filename, 'r:bom|utf-8') { |f| self.safe_load f }
    end

    def self.unsafe_load_file(filename)
      # https://github.com/tenderlove/psych/blob/v1.2.0/lib/psych.rb#L228-230
      File.open(filename, 'r:bom|utf-8') { |f| self.unsafe_load f }
    end

  else
    require "safe_yaml/syck_resolver"
    def self.safe_load(yaml)
      safe_resolver = SafeYAML::SyckResolver.new
      tree = YAML.parse(yaml)
      return safe_resolver.resolve_node(tree)
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

    if RUBY_VERSION >= "1.9.3"
      alias_method :load, :load_with_filename_and_options
    else
      alias_method :load, :load_with_options
    end

    alias_method :load_file, :load_file_with_options

    def enable_symbol_parsing?
      SafeYAML::OPTIONS[:enable_symbol_parsing]
    end

    def enable_symbol_parsing!
      SafeYAML::OPTIONS[:enable_symbol_parsing] = true
    end

    def disable_symbol_parsing!
      SafeYAML::OPTIONS[:enable_symbol_parsing] = false
    end

    def enable_arbitrary_object_deserialization?
      SafeYAML::OPTIONS[:enable_arbitrary_object_deserialization]
    end

    def enable_arbitrary_object_deserialization!
      SafeYAML::OPTIONS[:enable_arbitrary_object_deserialization] = true
    end

    def disable_arbitrary_object_deserialization!
      SafeYAML::OPTIONS[:enable_arbitrary_object_deserialization] = false
    end
  end

  private
  def self.safe_mode_from_options(method, options={})
    safe_mode = options[:safe]

    if safe_mode.nil?
      mode = SafeYAML::OPTIONS[:enable_arbitrary_object_deserialization] ? "unsafe" : "safe"
      Kernel.warn "Called '#{method}' without the :safe option -- defaulting to #{mode} mode."
      safe_mode = !SafeYAML::OPTIONS[:enable_arbitrary_object_deserialization]
    end

    safe_mode
  end
end
