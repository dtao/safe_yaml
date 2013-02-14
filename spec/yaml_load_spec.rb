require File.join(File.dirname(__FILE__), "spec_helper")

describe "safe_load" do
  let(:result) { @result }
  def parse(yaml)
    @result = YAML.load(yaml.unindent)
  end

  before :each do
    YAML.disable_symbol_parsing!
    SafeYAML::OPTIONS[:suppress_warnings] = true
  end

  context "by default" do
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

    it "translates sequences to arrays" do
      parse <<-YAML
        - foo
        - bar
        - baz
      YAML

      result.should == ["foo", "bar", "baz"]
    end

    it "translates most values to strings" do
      parse "string: value"
      result.should == { "string" => "value" }
    end

    it "does not deserialize symbols" do
      expect { parse ":symbol: value" }.to raise_error(SafeYAML::UnsafeTagError)
    end

    it "translates valid integral numbers to integers" do
      parse "integer: 1"
      result.should == { "integer" => 1 }
    end

    it "translates valid decimal numbers to floats" do
      parse "float: 3.14"
      result.should == { "float" => 3.14 }
    end

    it "translates valid dates" do
      parse "date: 2013-01-24"
      result.should == { "date" => Date.parse("2013-01-24") }
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

    it "translates quoted empty strings to strings (not nil)" do
      parse "foo: ''"
      result.should == { "foo" => "" }
    end

    it "correctly reverse-translates strings encoded via #to_yaml" do
      parse "5.10".to_yaml
      result.should == "5.10"
    end

    it "does not treat quoted strings as symbols" do
      parse <<-YAML
        - ":abcd"
        - ':abcd'
      YAML

      result.should == [":abcd", ":abcd"]
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

  context "with symbol parsing enabled" do
    before :each do
      YAML.enable_symbol_parsing!
    end

    after :each do
      YAML.disable_symbol_parsing!
    end

    it "translates values starting with ':' to symbols" do
      parse "symbol: :value"
      result.should == { "symbol" => :value }
    end

    it "applies the same transformation to keys" do
      parse ":bar: symbol"
      result.should == { :bar  => "symbol" }
    end

    it "applies the same transformation to elements in sequences" do
      parse "- :bar"
      result.should == [:bar]
    end
  end
end
