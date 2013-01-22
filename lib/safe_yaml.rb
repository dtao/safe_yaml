require "yaml"
require "safe_yaml/transform"
require "safe_yaml/version"

module YAML
  if RUBY_VERSION >= "1.9.2"
    require "safe_yaml/psych_handler"
    def self.safe_load(yaml)
      safe_handler = SafeYAML::PsychHandler.new
      Psych::Parser.new(safe_handler).parse(yaml)
      return safe_handler.result
    end

  else
    require "safe_yaml/syck_resolver"
    def self.safe_load(yaml)
      safe_resolver = SafeYAML::SyckResolver.new
      tree = YAML.parse(yaml)
      return safe_resolver.resolve_node(tree)
    end
  end

  def self.safe_load_file(filename)
    # from https://github.com/tenderlove/psych/blob/master/lib/psych.rb#L299
    File.open(filename, 'r:bom|utf-8') { |f| self.safe_load f }
  end

  class << self
    alias_method :orig_load, :load
    alias_method :load, :safe_load

    alias_method :orig_load_file, :load_file
    alias_method :load_file, :safe_load_file
  end
end
