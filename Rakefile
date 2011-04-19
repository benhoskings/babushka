require 'rake'
require 'rspec/core/rake_task'

desc 'Run the spec suite'
RSpec::Core::RakeTask.new('spec') {|t|
  t.rspec_opts = ['--colour', '--format Fuubar']
}

desc 'Profile the spec suite'
RSpec::Core::RakeTask.new('profile') {|t|
  t.rspec_opts = %w[--color --profile]
}

desc 'Run code coverage'
RSpec::Core::RakeTask.new('rcov') {|t|
  t.rcov = true
  t.rcov_opts = %w[--exclude spec]
}

task :default => :spec
