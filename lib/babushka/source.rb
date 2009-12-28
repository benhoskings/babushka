module Babushka
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
        log "# There #{sources.length == 1 ? 'is' : 'are'} #{sources.length} source#{'s' unless sources.length == 1}."
      }.each {|source|
        log Source.new(source).description
      }
    end
    def self.remove! name_or_uri, opts = {}
      sources.select {|source|
        name_or_uri.in? [source, source[:name], source[:uri]]
      }.each {|source|
        Source.new(source).remove! opts
      }
    end
    def self.clear! opts = {}
      sources.each {|source|
        Source.new(source).remove! opts
      }
    end

    require 'yaml'
    def self.sources_raw
      File.exists?(sources_yml) &&
      (yaml = YAML.load_file(sources_yml)) &&
      yaml[:sources] ||
      []
    end

    def self.sources
      sources_raw.each {|source| source[:uri] = source[:uri].p }
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
    def remove! opts = {}
      if opts[:force] || removeable?
        log_block "Removing #{name} (#{uri})" do
          remove_source and remove_repo
        end
      end
    end

    def removeable?
      if !self.class.sources.detect {|s| s[:name] == name }
        log "No such source: #{uri}"
      elsif !in_dir(path) { shell "git ls-files -mo" }.split("\n").empty?
        log "Local changes found in #{path}, not removing."
      elsif !in_dir(path) { shell('git rev-list origin/master..') }.lines.to_a.empty?
        log "There are unpushed commits in #{path}, not removing."
      else
        true
      end
    end

    include Shell::Helpers
    include GitHelpers
    def pull!
      returning git uri, :prefix => source_prefix, :dir => name, :log => true do
        FileUtils.touch path
      end
    end

    private

    def add_source
      write_sources self.class.sources.push(to_yaml).uniq
    end

    def remove_source
      write_sources self.class.sources - [to_yaml]
    end

    def write_sources sources
      File.open self.class.sources_yml, 'w' do |f|
        YAML.dump({:sources => sources}, f)
      end
    end

    def to_yaml
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
