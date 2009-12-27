$:.concat %w[spec/babushka spec/fancypath]

require 'bin/babushka'
include Babushka

include Babushka::LoggerHelpers
include Babushka::DepHelpers
include Babushka::Shell::Helpers

Dep.pool.clear!

require 'spec'
include Spec::DSL::Main

def tmp_prefix
  "#{'/private' if host.osx?}/tmp/rspec/its_ok_if_a_test_deletes_this/babushka"
end

FileUtils.rm_r tmp_prefix if File.exists? tmp_prefix
FileUtils.mkdir_p tmp_prefix unless File.exists? tmp_prefix

module Babushka
  class Source
    private
    def self.sources_yml
      tmp_prefix / 'sources.yml'
    end
    def source_prefix
      tmp_prefix / 'sources'
    end
  end
end


module Babushka
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

def print_log message, opts
  # Don't log while running specs.
end
