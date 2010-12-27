module Babushka
  VERSION        = '0.8.0'
  WorkingPrefix  = '~/.babushka'
  SourcePrefix   = '~/.babushka/sources'
  BuildPrefix    = '~/.babushka/build'
  DownloadPrefix = '~/.babushka/downloads'
  LogPrefix      = '~/.babushka/logs'
  VarsPrefix     = '~/.babushka/vars'
  ReportPrefix   = '~/.babushka/runs'

  module Path
    def self.binary() File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__ end
    def self.bin() File.dirname(binary) end
    def self.path() File.dirname(bin) end
    def self.lib() File.join(path, 'lib') end
    def self.run_from_path?() ENV['PATH'].split(':').include? File.dirname($0) end
  end
end

# First, load the component lists.
require File.join(Babushka::Path.path, 'lib', 'components')

# Load external components that babushka depends on.
Babushka::ExternalComponents.each {|c| require File.join(Babushka::Path.path, 'lib', c) }

# Next, load babushka itself.
Babushka::Components.each {|c| require File.join(Babushka::Path.path, 'lib/babushka', c) }

# Finally, mix in some top-level helper methods:
Object.class_eval {
  # Dep helpers like #Dep, #dep & #meta;
  include Babushka::Dep::Helpers
  # Logging helpers like #log, #log_ok, #log_error & #debug.
  include Babushka::LogHelpers
  # Shell helpers like #shell, #failable_shell & #sudo.
  include Babushka::ShellHelpers
  include Babushka::VersionOf::Helpers
}
