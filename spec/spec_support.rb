require 'bin/babushka'
include Babushka

include Babushka::BaseHelpers
include Babushka::LoggerHelpers
include Babushka::DepHelpers
include Babushka::ShellHelpers

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
end
