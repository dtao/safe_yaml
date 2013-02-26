require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe SafeYAML::Transform do
  it "should return the same encoding when decoding Base64" do
    value = "c3VyZS4="
    SafeYAML::Transform.to_proper_type(value, false, "!binary").encoding.should == value.encoding
  end
end
