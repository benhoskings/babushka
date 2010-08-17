#!/usr/bin/env ruby

babushka_components = %w[
  support/core_patches
  support/xml_string
  support/utils
  support/logger
  support/popen
  support/prompt_helpers
  support/shell
  support/shell_helpers
  support/suggest_helpers
  support/git_helpers
  support/resource
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
  babushka/pkg_helpers/yum_helper
  babushka/pkg_helpers/brew_helper
  babushka/pkg_helpers/gem_helper
  babushka/pkg_helpers/macports_helper
  babushka/pkg_helpers/src_helper
  babushka/dep
  babushka/dep_pool
  babushka/meta_dep_pool
  babushka/definer_helpers
  babushka/task
  babushka/source
  babushka/source_pool
  babushka/dep_runner
  babushka/dep_runners/base_dep_runner
  babushka/dep_runners/meta_dep_runner
  babushka/dep_definer
  babushka/dep_definers/meta_dep_wrapper
  babushka/dep_definers/base_dep_definer
  babushka/dep_definers/meta_dep_definer
]

require File.join(
  File.dirname(File.dirname(
    File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__)
  ),
  'lib/fancypath/fancypath'
)

module Babushka
  module Path
    def self.binary
      __FILE__.p.readlink
    end
    def self.bin
      binary.dir
    end
    def self.path
      bin.dir
    end
    def self.prefix
      path.dir
    end
    def self.run_from_path?
      ENV['PATH'].split(':').include? $0.p.dir
    end
  end
end

babushka_components.each {|component|
  require Babushka::Path.path / 'lib' / component
}

include Babushka::Logger::Helpers
include Babushka::Dep::Helpers
include Babushka::VersionOf::Helpers

if $0 == __FILE__
  # Running standalone - run the specified command and exit.
  exit Babushka::Base.run(ARGV) ? 0 : 1
end
