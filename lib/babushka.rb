module Babushka

  VERSION = '0.19.2'

  WORKING_PREFIX  = '~/.babushka'
  SOURCE_PREFIX   = '~/.babushka/sources'
  BUILD_PREFIX    = '~/.babushka/build'
  DOWNLOAD_PREFIX = '~/.babushka/downloads'
  LOG_PREFIX      = '~/.babushka/logs'

  module Path
    def self.binary() File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__ end
    def self.bin() File.dirname(binary) end
    def self.path() File.dirname(bin) end
    def self.lib() File.join(path, 'lib') end
    def self.run_from_path?() ENV['PATH'].split(':').include?(File.dirname($0)) end
  end
end

# First, load the component lists.
require File.join(Babushka::Path.path, 'lib', 'components')

# Load external components that babushka depends on.
Babushka::EXTERNAL_COMPONENTS.each {|c| require File.join(Babushka::Path.path, 'lib', c) }

# Next, load babushka itself.
Babushka::COMPONENTS.each {|c| require File.join(Babushka::Path.path, 'lib/babushka', c) }
