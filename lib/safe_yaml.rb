require "safe_yaml/handler"
require "safe_yaml/version"

module YAML
  def self.safe_load(yaml)
    safe_handler = SafeYAML::Handler.new
    Psych::Parser.new(safe_handler).parse(yaml)
    return safe_handler.result
  end
end
