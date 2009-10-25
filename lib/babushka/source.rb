module Babushka
  module SourceHelpers
    def self.included base # :nodoc:
      base.send :include, HelperMethods
    end

    module HelperMethods
      def Source uri
        Source.new(uri).path
      end
    end
  end

  class Source

    attr_reader :uri

    def self.pull!
      sources.all? {|source|
        Source.new(source).pull!
      }
    end
    def self.add! arg
      new(arg.respond_to?(:value) ? arg.value : arg).add!
    end
    def self.list! arg
      sources.tap {|sources|
        log "There #{sources.length == 1 ? 'is' : 'are'} #{sources.length} source#{'s' unless sources.length == 1}."
      }.each {|source|
        log source
      }
    end
    def self.remove! arg
      new(arg.respond_to?(:value) ? arg.value : arg).remove!
    end
    def self.clear! arg
      sources.each {|source|
        new(source).remove!
      }
    end

    require 'yaml'
    def self.sources
      File.exists?(sources_yml) &&
      (yaml = YAML.load_file(sources_yml)) &&
      yaml[:sources] ||
      []
    end

    def self.paths
      sources.map {|uri|
        Source.new(uri).path
      }
    end

    def self.count
      sources.length
    end

    require 'uri'
    def initialize uri
      @uri = URI.parse uri.to_s
    end

    def path
      source_prefix / name
    end
    def name
      uri.path.gsub('/', '_').gsub(/\.+\//, '')
    end
    def cloned?
      File.directory? path / '.git'
    end

    def add!
      log "#{cloned? ? 'Updating' : 'Adding'} #{name}", :closing_status => :status_only do
        pull! and add_source
      end
    end
    def remove!
      if !self.class.sources.include?(uri.to_s)
        log "No such source: #{uri}"
      else
        log_block "Removing #{name}" do
          remove_repo and remove_source
        end
      end
    end

    include ShellHelpers
    include GitHelpers
    def pull!
      git uri, :prefix => source_prefix, :dir => name
    end

    private

    def add_source
      prev_sources = self.class.sources
      File.open self.class.sources_yml, 'w' do |f|
        YAML.dump({:sources => prev_sources.push(uri.to_s).uniq}, f)
      end
    end

    def remove_source
      prev_sources = self.class.sources
      File.open self.class.sources_yml, 'w' do |f|
        YAML.dump({:sources => (prev_sources - [uri.to_s])}, f)
      end
    end

    def remove_repo
      !File.exists?(path) || FileUtils.rm_r(path)
    end

    def self.sources_yml
      Path.path / 'sources.yml'
    end
    def source_prefix
      Path.path / 'sources'
    end

  end
end
