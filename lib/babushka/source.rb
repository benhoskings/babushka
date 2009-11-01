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

    attr_reader :name, :uri

    def self.pull!
      sources.all? {|(name, uri)|
        Source.new(name, uri).pull!
      }
    end
    def self.add! name, uri
      new(name, uri).add!
    end
    def self.list!
      sources.tap {|sources|
        log "There #{sources.length == 1 ? 'is' : 'are'} #{sources.length} source#{'s' unless sources.length == 1}."
      }.each_pair {|name, uri|
        log Source.new(name, uri).description
      }
    end
    def self.remove! name_or_uri
      sources.selekt {|name, uri|
        [name, uri].include? name_or_uri
      }.each_pair {|name, uri|
        new(name, uri).remove!
      }
    end
    def self.clear!
      sources.each_pair {|name,uri|
        new(name, uri).remove!
      }
    end

    require 'yaml'
    def self.sources
      File.exists?(sources_yml) &&
      (yaml = YAML.load_file(sources_yml)) &&
      yaml[:sources] ||
      {}
    end

    def self.paths
      sources.map {|name, uri|
        Source.new(name, uri).path
      }
    end

    def self.count
      sources.length
    end

    require 'uri'
    def initialize name, uri
      @name = name
      @uri = URI.parse uri.to_s
    end

    def path
      source_prefix / name
    end
    def updated_at
      Time.now - File.mtime(path)
    end
    def description
      "#{name} - #{uri} (updated #{updated_at.round.xsecs} ago)"
    end
    def cloned?
      File.directory? path / '.git'
    end

    def add!
      returning pull! && add_source do |result|
        log_ok "Added #{name}." if result
      end
    end
    def remove!
      if !self.class.sources.has_key?(name)
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
      returning git uri, :prefix => source_prefix, :dir => name do
        FileUtils.touch path
      end
    end

    private

    def add_source
      write_sources self.class.sources.merge name => uri.to_s
    end

    def remove_source
      write_sources self.class.sources.reject {|k,v| [k, v] == [name, uri.to_s] }
    end

    def write_sources sources
      File.open self.class.sources_yml, 'w' do |f|
        YAML.dump({:sources => sources}, f)
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
