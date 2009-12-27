#!/usr/bin/env ruby

require 'lib/fancypath/fancypath'

babushka_components = %w[
  support/core_patches
  support/utils
  support/logger
  support/popen
  support/prompt_helpers
  support/shell
  support/shell_helpers
  support/suggest_helpers
  support/git_helpers
  support/lambda_chooser
  support/ip
  support/version_str
  support/version_of
  support/version_list
  support/colorizer
  support/levenshtein

  babushka/structs
  babushka/cmdline
  babushka/base
  babushka/system_spec
  babushka/bug_reporter
  babushka/pkg_helper
  babushka/pkg_helpers/base_helper
  babushka/pkg_helpers/apt_helper
  babushka/pkg_helpers/brew_helper
  babushka/pkg_helpers/gem_helper
  babushka/pkg_helpers/macports_helper
  babushka/pkg_helpers/src_helper
  babushka/dep
  babushka/dep_pool
  babushka/definer_helpers
  babushka/source
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

module Babushka
  module Path
    def self.binary
      __FILE__.to_path.readlink
    end
    def self.bin
      binary.dir
    end
    def self.path
      bin.dir
    end
  end
end

babushka_components.each {|component|
  require File.join Babushka::Path.path, 'lib', component
}

include Babushka::Logger::Helpers
include Babushka::Dep::Helpers
include Babushka::VersionOf::Helpers

if $0 == __FILE__
  # Running standalone - run the specified command and exit.
  exit Babushka::Base.run(ARGV) ? 0 : 1
else
  # Required - just init and load deps.
  Babushka::Base.setup_noninteractive
end
