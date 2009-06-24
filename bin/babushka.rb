%w[
  support/core_patches.rb
  support/utils.rb
  support/logger.rb
  support/popen.rb
  support/prompt_helpers.rb
  support/shell_helpers.rb

  babushka/base.rb
  babushka/shell.rb
  babushka/pkg_manager.rb
  babushka/dep.rb
  babushka/dep_definer.rb

].each {|component|
  require "#{File.dirname(__FILE__)}/../lib/#{component}"
}

include Babushka::BaseHelpers
include Babushka::LoggerHelpers
include Babushka::DepHelpers

Babushka ARGV
