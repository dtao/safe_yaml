require File.join(File.dirname(__FILE__), "spec_helper")

require "safe_yaml"
require "exploitable_back_door"

describe YAML do
  describe "load" do
    it "allows exploits through objects defined in YAML w/ !ruby/hash" do
      YAML.load "--- !ruby/hash:ExploitableBackDoor\nfoo: bar\n"
      ExploitableBackDoor.should be_exploited
    end
  end

  describe "safe_load" do
    it "does NOT allow exploits through objects defined in YAML w/ !ruby/hash" do
      YAML.safe_load "--- !ruby/hash:ExploitableBackDoor\nfoo: bar\n"
      ExploitableBackDoor.should_not be_exploited
    end

    it "loads a plain ol' YAML document just fine" do
      result = YAML.safe_load <<-YAML.unindent
        foo:
          number: 1
          string: Hello, there!
          symbol: :blah
          sequence:
            - hi
            - bye
      YAML

      result.should == {
        "foo" => {
          "number" => 1,
          "string" => "Hello, there!",
          "symbol" => :blah,
          "sequence" => ["hi", "bye"]
        }
      }
    end
  end
end
