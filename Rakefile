require "rspec/core/rake_task"

if ENV["YAMLER"] && defined?(YAML::ENGINE)
  YAML::ENGINE.yamler = ENV["YAMLER"]
end

require "safe_yaml"

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  puts "Running specs in Ruby #{RUBY_VERSION} on #{RUBY_PLATFORM} with '#{SafeYAML::YAML_ENGINE}' YAML engine."
  t.rspec_opts = %w(--color)
end

desc "Run perf tests"
task :perf, :append_perf_test_results do |t, args|
  ENV["APPEND_PERF_TEST_RESULTS"] = args[:append_perf_test_results]
  puts "Running performance tests in Ruby #{RUBY_VERSION} on #{RUBY_PLATFORM} with '#{SafeYAML::YAML_ENGINE}' YAML engine."
  require File.join(File.dirname(__FILE__), "perf", "performance_tests.rb")
end
