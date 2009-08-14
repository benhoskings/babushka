require 'bin/babushka'
include Babushka

include Babushka::BaseHelpers
include Babushka::LoggerHelpers
include Babushka::DepHelpers
include Babushka::ShellHelpers

require 'spec'
include Spec::DSL::Main

def tmp_prefix
  "#{'/private' if osx?}/tmp/rspec/its_ok_if_a_test_deletes_this"
end

module Babushka
  class Logger
    def self.log message, opts = {}, &block
      # Don't log while running specs.
      yield if block_given?
    end
  end
  class VersionOf
    # VersionOf#== should return false in testing unless other is also a VersionOf.
    def == other
      if other.is_a? VersionOf
        name == other.name &&
        version == other.version
      end
    end
  end
end
