$:.concat %w[spec/babushka spec/fancypath spec/inkan .]

require 'lib/babushka'
include Babushka
include Babushka::DSL

require 'rubygems'
require 'rspec'
require 'ir_b'

puts "babushka@#{`git rev-parse --short HEAD`.strip} | ruby-#{RUBY_VERSION} | rspec-#{RSpec::Version::STRING}"

def tmp_prefix
  @@tmp_prefix ||= "/#{File.symlink?('/tmp') ? File.readlink('/tmp') : 'tmp'}/from_babushka_specs".tap {|path|
    path.p.rm.mkdir
  }
end

module Babushka
  class Asset
    def build_prefix
      tmp_prefix / 'archives'
    end
  end

  class Source

    private

    def self.source_prefix
      tmp_prefix / 'sources'
    end

    def self.for_remote name
      Source.new(default_remote_for(name), :name => name).tap {|source|
        source.stub!(:update!) # don't hit the network to update sources during specs.
      }
    end
  end

  class Logging
    def self.print_log message, printable, as
      # Don't log while running specs.
    end
  end

  class BugReporter
    def self.report dep
      # Don't report exceptions during tests.
    end
  end
end
