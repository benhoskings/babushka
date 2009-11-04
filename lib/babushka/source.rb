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
      sources.all? {|source|
        new(source).pull!
      }
    end
    def self.add! name, uri
      new(:name => name, :uri => uri).add!
    end
    def self.list!
      sources.tap {|sources|
        log "There #{sources.length == 1 ? 'is' : 'are'} #{sources.length} source#{'s' unless sources.length == 1}."
      }.each {|source|
        log Source.new(source).description
      }
    end
    def self.remove! name_or_uri
      sources.select {|source|
        name_or_uri.in? [source, source[:name], source[:uri]]
      }.each {|source|
        Source.new(source).remove!
      }
    end
    def self.clear!
      sources.each {|source|
        Source.new(source).remove!
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
      sources.map {|source|
        Source.new(source).path
      }
    end

    def self.count
      sources.length
    end

    require 'uri'
    def initialize hsh
      @name = hsh[:name]
      @uri = URI.parse hsh[:uri].to_s
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
      if !self.class.sources.detect {|s| s[:name] == name }
        log "No such source: #{uri}"
      elsif !in_dir(path) { shell "git ls-files -mo" }.split("\n").empty?
        log "Local changes found in #{path}, not removing."
      else
        log_block "Removing #{name} (#{uri})" do
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
      write_sources self.class.sources.push(data_for_yaml).uniq
    end

    def remove_source
      write_sources self.class.sources - [data_for_yaml]
    end

    def write_sources sources
      File.open self.class.sources_yml, 'w' do |f|
        YAML.dump({:sources => sources}, f)
      end
    end

    def data_for_yaml
      {:name => name, :uri => uri.to_s}
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
