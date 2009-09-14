%w[
  support/core_patches
  support/utils
  support/logger
  support/popen
  support/prompt_helpers
  support/shell_helpers
  support/lambda_chooser
  support/version_str
  support/version_of
  support/version_list
  support/colorizer

  babushka/base
  babushka/shell
  babushka/pkg_manager
  babushka/dep
  babushka/definer_helpers
  babushka/task
  babushka/dep_runner
  babushka/dep_runners/base_dep_runner
  babushka/dep_runners/pkg_dep_runner
  babushka/dep_runners/gem_dep_runner
  babushka/dep_runners/src_dep_runner
  babushka/dep_runners/ext_dep_runner
  babushka/dep_runners/brew_dep_runner
  babushka/dep_definer
  babushka/dep_definers/base_dep_definer
  babushka/dep_definers/pkg_dep_definer
  babushka/dep_definers/gem_dep_definer
  babushka/dep_definers/src_dep_definer
  babushka/dep_definers/ext_dep_definer
  babushka/dep_definers/brew_dep_definer

].each {|component|
  require "#{File.dirname(__FILE__)}/../lib/#{component}"
}

include Babushka::LoggerHelpers
include Babushka::DepHelpers
include Babushka::VersionHelpers

if $0 == __FILE__
  Babushka::Base.run ARGV
else
  Babushka::Base.setup_noninteractive
end
