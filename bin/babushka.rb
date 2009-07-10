%w[
  support/core_patches
  support/utils
  support/logger
  support/popen
  support/prompt_helpers
  support/shell_helpers
  support/lambda_chooser
  support/lambda_list
  support/version_str

  babushka/base
  babushka/shell
  babushka/pkg_manager
  babushka/dep
  babushka/definer_helpers
  babushka/dep_definer
  babushka/dep_definers/base_dep_definer
  babushka/dep_definers/pkg_dep_definer
  babushka/dep_definers/gem_dep_definer
  babushka/dep_definers/ext_dep_definer

].each {|component|
  require "#{File.dirname(__FILE__)}/../lib/#{component}"
}

include Babushka::BaseHelpers
include Babushka::LoggerHelpers
include Babushka::DepHelpers

Babushka ARGV if $0 == __FILE__
