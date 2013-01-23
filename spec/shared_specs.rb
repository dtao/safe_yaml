require File.join(File.dirname(__FILE__), "spec_helper")

require "safe_yaml/transform"

module SharedSpecs
  def self.included(base)
    base.instance_eval do
      it "translates maps to hashes" do
        parse <<-YAML
          potayto: potahto
          tomayto: tomahto
        YAML

        result.should == {
          "potayto" => "potahto",
          "tomayto" => "tomahto"
        }
      end

      it "translates most values to strings" do
        parse "string: value"
        result.should == { "string" => "value" }
      end

      it "translates values starting with ':' to symbols" do
        parse "symbol: :value"
        result.should == { "symbol" => :value }
      end

      it "translates valid integral numbers to integers" do
        parse "integer: 1"
        result.should == { "integer" => 1 }
      end

      it "translates valid decimal numbers to floats" do
        parse "float: 3.14"
        result.should == { "float" => 3.14 }
      end

      it "translates sequences to arrays" do
        parse <<-YAML
          - foo
          - bar
          - baz
        YAML

        result.should == ["foo", "bar", "baz"]
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

      it "applies the same transformations to keys as to values" do
        parse <<-YAML
          foo: string
          :bar: symbol
          1: integer
          3.14: float
        YAML

        result.should == {
          "foo" => "string",
          :bar  => "symbol",
          1     => "integer",
          3.14  => "float"
        }
      end

      it "applies the same transformations to elements in sequences as to all values" do
        parse <<-YAML
          - foo
          - :bar
          - 1
          - 3.14
        YAML

        result.should == ["foo", :bar, 1, 3.14]
      end

      it "deals just fine with nested maps" do
        parse <<-YAML
          foo:
            bar:
              marco: polo
        YAML

        result.should == { "foo" => { "bar" => { "marco" => "polo" } } }
      end

      it "deals just fine with nested sequences" do
        parse <<-YAML
          - foo
          -
            - bar1
            - bar2
            -
              - baz1
              - baz2
        YAML

        result.should == ["foo", ["bar1", "bar2", ["baz1", "baz2"]]]
      end
    end
  end
end
