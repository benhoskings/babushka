module Babushka

  VERSION = '0.17.7'

  WORKING_PREFIX  = '~/.babushka'
  SOURCE_PREFIX   = '~/.babushka/sources'
  BUILD_PREFIX    = '~/.babushka/build'
  DOWNLOAD_PREFIX = '~/.babushka/downloads'
  LOG_PREFIX      = '~/.babushka/logs'
  VARS_PREFIX     = '~/.babushka/vars'
  REPORT_PREFIX   = '~/.babushka/runs'

  def self.const_missing const_name
    if %w[
      WorkingPrefix
      SourcePrefix
      BuildPrefix
      DownloadPrefix
      LogPrefix
      VarsPrefix
      ReportPrefix
    ].include?(const_name.to_s)
      const_case = const_name.to_s.scan(/[A-Z][a-z]+/).map(&:upcase).join('_')
      Babushka::LogHelpers.deprecated! "2013-12-15", :method_name => "Babushka::#{const_name}", :instead => "Babushka::#{const_case}"
      Babushka.const_get(const_case)
    else
      super
    end
  end

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
