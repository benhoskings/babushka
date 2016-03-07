$:.concat %w[spec/babushka spec/fancypath spec/inkan .]

require 'lib/babushka'
include Babushka::DSL

require 'rubygems'
require 'rspec'
require 'ir_b'

puts "babushka@#{`git rev-parse --short HEAD`.strip} | ruby-#{RUBY_VERSION}p#{RUBY_PATCHLEVEL} | rspec-#{RSpec::Version::STRING}"

if ENV['TRAVIS']
  `git config --global user.email "hello@babushka.me"`
  `git config --global user.name "babushka specs"`
end

def tmp_prefix
  Babushka::Specs.tmp_prefix
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.example_status_persistence_file_path = "spec/examples.txt"
  config.default_formatter = 'doc' if config.files_to_run.one?
end

module Babushka
  module Specs
    def self.tmp_prefix
      @tmp_prefix ||= "/#{File.symlink?('/tmp') ? File.readlink('/tmp') : 'tmp'}/from_babushka_specs".tap {|path|
        path.p.rm.mkdir
      }
    end
  end

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
  end

  class Task
    def log_prefix
      tmp_prefix / 'logs'
    end
  end

  class Logging
    def self.print_log message, printable, as
      # Don't log while running specs.
    end
  end
end
