require File.join(File.dirname(__FILE__), "spec_helper")

require "handler"

describe SafeYAML::Handler do
  let(:handler) { SafeYAML::Handler.new }
  let(:parser) { Psych::Parser.new(handler) }

  describe "basic usage" do
    it "will construct simple hashes or arrays from maps and sequences" do
      parser.parse <<-YAML.unindent
        foo:
          - bar
          - baz
      YAML

      handler.result.should == { "foo" => ["bar", "baz"] }
    end
  end

  describe "more complex usage" do
    it "deals just fine with nested maps" do
      parser.parse <<-YAML.unindent
        foo:
          bar:
            marco: polo
      YAML

      handler.result.should == { "foo" => { "bar" => { "marco" => "polo" } } }
    end
  end
end
