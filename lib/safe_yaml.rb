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

module YAML
  if RUBY_VERSION >= "1.9.3"
    require "safe_yaml/psych_handler"
    def self.safe_load(yaml, filename=nil)
      safe_handler = SafeYAML::PsychHandler.new
      Psych::Parser.new(safe_handler).parse(yaml, filename)
      return safe_handler.result
    end

    def self.orig_load_file(filename)
      # https://github.com/tenderlove/psych/blob/v1.3.2/lib/psych.rb#L296-298
      File.open(filename, 'r:bom|utf-8') { |f| self.orig_load f, filename }
    end

  elsif RUBY_VERSION == "1.9.2"
    require "safe_yaml/psych_handler"
    def self.safe_load(yaml)
      safe_handler = SafeYAML::PsychHandler.new
      Psych::Parser.new(safe_handler).parse(yaml)
      return safe_handler.result
    end

    def self.orig_load_file(filename)
      # https://github.com/tenderlove/psych/blob/v1.2.0/lib/psych.rb#L228-230
      File.open(filename, 'r:bom|utf-8') { |f| self.orig_load f }
    end

  else
    require "safe_yaml/syck_resolver"
    def self.safe_load(yaml)
      safe_resolver = SafeYAML::SyckResolver.new
      tree = YAML.parse(yaml)
      return safe_resolver.resolve_node(tree)
    end

    def self.orig_load_file(filename)
      # https://github.com/indeyets/syck/blob/master/ext/ruby/lib/yaml.rb#L133-135
      File.open(filename) { |f| self.orig_load f }
    end
  end

  class << self
    alias_method :orig_load, :load
    alias_method :load, :safe_load

    def enable_symbol_parsing
      SafeYAML::Transform::OPTIONS[:enable_symbol_parsing]
    end

    def enable_symbol_parsing=(value)
      SafeYAML::Transform::OPTIONS[:enable_symbol_parsing] = value
    end
  end
end
