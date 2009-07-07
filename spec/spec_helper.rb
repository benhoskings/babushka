require 'bin/babushka'
include Babushka

include Babushka::BaseHelpers
include Babushka::LoggerHelpers
include Babushka::DepHelpers
include Babushka::ShellHelpers

def tmp_prefix
  "#{'/private' if osx?}/tmp/rspec/its_ok_if_a_test_deletes_this"
end
