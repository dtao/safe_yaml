require File.join(File.dirname(__FILE__), "spec_helper")

require "safe_yaml/transform"

module SharedSpecs
  def self.included(base)
    base.instance_eval do
      it "translates most values to strings" do
        parse "key: value"
        result.should == { "key" => "value" }
      end

      it "translates values starting with ':' to symbols" do
        parse ":key: value"
        result.should == { :key => "value" }
      end

      it "translates valid integral numbers to integers" do
        parse "integer: 1"
        result.should == { "integer" => 1 }
      end

      it "translates valid decimal numbers to floats" do
        parse "float: 3.14"
        result.should == { "float" => 3.14 }
      end

      it "translates valid true/false values to booleans" do
        parse <<-YAML
          - yes
          - true
          - no
          - false
        YAML

        result.should == [true, true, false, false]
      end

      it "translates valid nulls to nil" do
        parse <<-YAML
          - 
          - ~
          - null
        YAML

        result.should == [nil] * 3
      end

      it "applies the same transformations to values as to keys" do
        parse <<-YAML
          string: value
          symbol: :value
          integer: 1
          float: 3.14
        YAML

        result.should == {
          "string" => "value",
          "symbol" => :value,
          "integer" => 1,
          "float" => 3.14
        }
      end

      it "translates sequences to arrays" do
        parse <<-YAML
          - foo
          - bar
          - baz
        YAML

        result.should == ["foo", "bar", "baz"]
      end

      it "applies the same transformations to elements in sequences as to all values" do
        parse <<-YAML
          - string
          - :symbol
          - 1
          - 3.14
        YAML

        result.should == ["string", :symbol, 1, 3.14]
      end

      it "translates maps to hashes" do
        parse <<-YAML
          foo: blah
          bar: glah
          baz: flah
        YAML

        result.should == {
          "foo" => "blah",
          "bar" => "glah",
          "baz" => "flah"
        }
      end

      it "applies the same transformations to values in hashes as to all values" do
        parse <<-YAML
          foo: :symbol
          bar: 1
          baz: 3.14
        YAML

        result.should == {
          "foo" => :symbol,
          "bar" => 1,
          "baz" => 3.14
        }
      end

      it "deals just fine with nested maps" do
        parse <<-YAML
          foo:
            bar:
              marco: polo
        YAML

        result.should == { "foo" => { "bar" => { "marco" => "polo" } } }
      end
    end
  end
end
