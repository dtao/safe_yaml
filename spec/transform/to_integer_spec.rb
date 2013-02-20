require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe SafeYAML::Transform::ToInteger do
  it "returns true when the value matches a valid Integer" do
    subject.transform?("10").should be_true
  end

  it "returns false when the value does not match a valid Integer" do
    subject.transform?("foobar").should be_false
  end

  it "returns false when the value spans multiple lines" do
    subject.transform?("10\nNOT AN INTEGER").should be_false
  end

  it "correctly parses numbers in octal format" do
    subject.transform?("010").should == [true, 8]
  end

  it "correctly parses numbers in hexadecimal format" do
    subject.transform?("0x1FF").should == [true, 511]
  end

  it "defaults to a string for a number that resembles octal format but is not" do
    subject.transform?("09").should be_false
  end

  it "defaults to a string for a number that resembles hexadecimal format but is not" do
    subject.transform?("0x1G").should be_false
  end
end
