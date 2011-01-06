# -*- coding: utf-8 -*-

$:.concat %w[spec/babushka spec/fancypath spec/inkan .]

require 'lib/babushka'
include Babushka

require 'rubygems'
require 'rspec'
Rspec.configure

puts "babushka@#{`git rev-parse --short HEAD`.strip} • ruby-#{RUBY_VERSION} • rspec-#{RSpec::Version::STRING}"

def tmp_prefix
  "#{'/private' if Base.host.osx?}/tmp/rspec/its_ok_if_a_test_deletes_this/babushka"
end

`rm -rf '#{tmp_prefix}'` if File.exists? tmp_prefix
`mkdir -p '#{tmp_prefix}'` unless File.exists? tmp_prefix

module Babushka
  class Resource
    def archive_prefix
      tmp_prefix / 'archives'
    end
  end

  class Source
    def remove!
      !cloneable? || !File.exists?(path) || `rm -rf '#{path}'`
    end
    private
    def self.sources_yml
      tmp_prefix / 'sources.yml'
    end
    def self.source_prefix
      tmp_prefix / 'sources'
    end
    def self.for_remote name
      Source.new(default_remote_for(name, :github), :name => name).tap {|source|
        source.stub!(:update!) # don't hit the network to update sources during specs.
      }
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

  module LogHelpers
    def print_log message, opts
      # Don't log while running specs.
    end
  end

  class BugReporter
    def self.report dep
      # Don't report exceptions during tests.
    end
  end
end
