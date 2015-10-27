require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new

# All-in-one target for CI servers to run.
task :ci => ['spec']
