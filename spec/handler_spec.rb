require File.join(File.dirname(__FILE__), "spec_helper")

require "safe_yaml/handler"

describe SafeYAML::Handler do
  let(:handler) { SafeYAML::Handler.new }
  let(:parser) { Psych::Parser.new(handler) }
  let(:result) { handler.result }

  def parse(yaml)
    parser.parse(yaml.unindent)
  end

  it "translates most values to strings" do
    parser.parse "key: value"
    result.should == { "key" => "value" }
  end

  it "translates values starting with ':' to symbols" do
    parser.parse ":key: value"
    result.should == { :key => "value" }
  end

  it "translates valid integral numbers to integers" do
    parser.parse "integer: 1"
    result.should == { "integer" => 1 }
  end

  it "translates valid decimal numbers to floats" do
    parser.parse "float: 3.14"
    result.should == { "float" => 3.14 }
  end

  it "translates valid true/false values to booleans" do
    parser.parse <<-YAML
      - yes
      - true
      - no
      - false
    YAML

    result.should == [true, true, false, false]
  end

  it "translates valid nulls to nil" do
    parser.parse <<-YAML
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

  it "deals just fine with aliases and anchors" do
    parse <<-YAML
      - &id001 {}
      - *id001
      - *id001
    YAML

    result.should == [{}, {}, {}]
  end
end
