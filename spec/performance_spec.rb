require File.join(File.dirname(__FILE__), "spec_helper")

describe "SafeYAML performance", :perf => true do
  before :each do
    SafeYAML::OPTIONS[:default_mode] = :safe
  end

  def self.add_test(description, yaml, repetitions=10)
    yaml = yaml.unindent
    expected_result = YAML.unsafe_load(yaml)
    safe_result = YAML.safe_load(yaml)

    raise "Wait -- results don't match!" if safe_result != expected_result

    example("#{description} - unsafe") do
      repetitions.times do
        YAML.unsafe_load(yaml)
      end
    end

    example("#{description} - safe") do
      repetitions.times do
        YAML.safe_load(yaml)
      end
    end
  end

  add_test "parsing a huge YAML document", File.read(File.join(__dir__, "perf_test.yml"))
end
