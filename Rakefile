require "rspec/core/rake_task"

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w(--color)
end

desc "Run perf tests"
RSpec::Core::RakeTask.new(:perf) do |t|
  t.rspec_opts = %w(--color --require=rperft --format=RPerft::RSpecFormatter --tag=@perf)
end
