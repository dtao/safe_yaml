require "spec_helper"

describe SafeYAML::Transform::ToDate do
  it "returns true when the value matches a valid Date" do
    expect(subject.transform?("2013-01-01")).to eq([true, Date.parse("2013-01-01")])
  end

  it "returns false when the value does not match a valid Date" do
    expect(subject.transform?("foobar")).to be_falsey
  end

  it "returns false when the value does not end with a Date" do
    expect(subject.transform?("2013-01-01\nNOT A DATE")).to be_falsey
  end

  it "returns false when the value does not begin with a Date" do
    expect(subject.transform?("NOT A DATE\n2013-01-01")).to be_falsey
  end

  it "correctly parses the remaining formats of the YAML spec" do
    equivalent_values = [
      "2001-12-15T02:59:43.1Z", # canonical
      "2001-12-14t21:59:43.10-05:00", # iso8601
      "2001-12-14 21:59:43.10 -5", # space separated
      "2001-12-15 2:59:43.10" # no time zone (Z)
    ]

    equivalent_values.each do |value|
      success, result = subject.transform?(value)
      expect(success).to be_truthy
      expect(result).to eq(Time.utc(2001, 12, 15, 2, 59, 43, 100000))
    end
  end

  if RUBY_VERSION < "2.4"
    # https://docs.ruby-lang.org/en/2.4.0/NEWS.html#label-Stdlib+compatibility+issues+-28excluding+feature+bug+fixes-29
    # https://github.com/dtao/safe_yaml/pull/87
    # https://github.com/jekyll/jekyll/issues/5963
    # https://github.com/jekyll/jekyll/pull/6697
    it "converts times to the local timezone" do
      success, result = subject.transform?("2012-12-01 10:33:45 +11:00")
      expect(success).to be_truthy
      expect(result).to eq(Time.utc(2012, 11, 30, 23, 33, 45))
      expect(result.gmt_offset).to eq(Time.local(2012, 11, 30).gmt_offset)
    end
  else
    it "preserves times timezone" do
      success, result = subject.transform?("2012-12-01 10:33:45 +11:00")
      expect(success).to be_truthy
      expect(result).to eq(Time.utc(2012, 11, 30, 23, 33, 45))
      expect(result.gmt_offset).to eq(11*60*60)
    end
  end

  it "returns strings for invalid dates" do
    expect(subject.transform?("0000-00-00")).to eq([true, "0000-00-00"])
    expect(subject.transform?("2013-13-01")).to eq([true, "2013-13-01"])
    expect(subject.transform?("2014-01-32")).to eq([true, "2014-01-32"])
  end

  it "returns strings for invalid date/times" do
    expect(subject.transform?("0000-00-00 00:00:00 -0000")).to eq([true, "0000-00-00 00:00:00 -0000"])
    expect(subject.transform?("2013-13-01 21:59:43 -05:00")).to eq([true, "2013-13-01 21:59:43 -05:00"])
    expect(subject.transform?("2013-01-32 21:59:43 -05:00")).to eq([true, "2013-01-32 21:59:43 -05:00"])
    expect(subject.transform?("2013-01-30 25:59:43 -05:00")).to eq([true, "2013-01-30 25:59:43 -05:00"])
    expect(subject.transform?("2013-01-30 21:69:43 -05:00")).to eq([true, "2013-01-30 21:69:43 -05:00"])

    # Interesting. It seems that in some older Ruby versions, the below actually parses successfully
    # w/ DateTime.parse; but it fails w/ YAML.load. Whom to follow???

    # subject.transform?("2013-01-30 21:59:63 -05:00").should == [true, "2013-01-30 21:59:63 -05:00"]
  end
end
