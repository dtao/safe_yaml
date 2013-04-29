require "rspec/core/rake_task"

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w(--color)
end

desc "Run perf tests"
task :perf do
  require File.join(File.dirname(__FILE__), "perf", "performance_tests.rb")
end
