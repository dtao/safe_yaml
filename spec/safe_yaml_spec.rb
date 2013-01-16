require File.join(File.dirname(__FILE__), "spec_helper")

require "safe_yaml"

describe YAML do
  describe "safe_load" do
    it "loads a plain ol' YAML document just fine" do
      result = YAML.safe_load <<-YAML.unindent
        foo:
          number: 1
          string: Hello, there!
          sequence:
            - hi
            - bye
      YAML

      result.should == {
        "foo" => {
          "number" => 1,
          "string" => "Hello, there!",
          "sequence" => ["hi", "bye"]
        }
      }
    end
  end
end
