#!/usr/bin/env ruby

babushka_components = %w[
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
  babushka/bug_reporter
  babushka/pkg_helper
  babushka/pkg_helpers/apt_helper
  babushka/pkg_helpers/brew_helper
  babushka/pkg_helpers/gem_helper
  babushka/pkg_helpers/macports_helper
  babushka/dep
  babushka/definer_helpers
  babushka/task
  babushka/dep_runner
  babushka/dep_runners/base_dep_runner
  babushka/dep_runners/pkg_dep_runner
  babushka/dep_runners/gem_dep_runner
  babushka/dep_runners/src_dep_runner
  babushka/dep_runners/ext_dep_runner
  babushka/dep_definer
  babushka/dep_definers/base_dep_definer
  babushka/dep_definers/pkg_dep_definer
  babushka/dep_definers/gem_dep_definer
  babushka/dep_definers/src_dep_definer
  babushka/dep_definers/ext_dep_definer
]

def real_bin_babushka
  File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
end

babushka_components.each {|component|
  require "#{File.dirname(real_bin_babushka)}/../lib/#{component}"
}

include Babushka::LoggerHelpers
include Babushka::DepHelpers
include Babushka::VersionHelpers

if $0 == __FILE__
  exit Babushka::Base.run(ARGV) ? 0 : 1
else
  Babushka::Base.setup_noninteractive
end
