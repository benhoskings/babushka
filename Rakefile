require 'rake'
require 'rspec/core/rake_task'

desc 'Run the spec suite'
RSpec::Core::RakeTask.new('spec') {|t|
  opts = ['--color']
  opts << '--format Fuubar' if STDIN.tty?
  t.rspec_opts = opts
}

desc 'Run the acceptance suite'
RSpec::Core::RakeTask.new('acceptance') {|t|
  t.pattern = "./spec/acceptance/*.rb"
  t.rspec_opts = ['--colour']
}

desc 'Profile the spec suite'
RSpec::Core::RakeTask.new('profile') {|t|
  t.rspec_opts = ['--colour', '--format Fuubar', '--profile']
}

desc 'Run code coverage'
RSpec::Core::RakeTask.new('rcov') {|t|
  t.rcov = true
  t.rcov_opts = %w[--exclude spec]
}

task :default => :spec
