require "yaml"
require "handler"

module YAML
  def self.safe_load(yaml)
    safe_handler = SafeYAML::Handler.new
    Psych::Parser.new(safe_handler).parse(yaml)
    return safe_handler.result
  end
end
