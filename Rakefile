require 'rake'
require 'rspec/core/rake_task'

desc 'Run the spec suite'
RSpec::Core::RakeTask.new('spec')

desc 'Run code coverage'
RSpec::Core::RakeTask.new('rcov') {|t|
  t.rcov = true
  t.rcov_opts = %w[--exclude spec]
}

task :default => :spec
