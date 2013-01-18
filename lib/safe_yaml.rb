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
end
