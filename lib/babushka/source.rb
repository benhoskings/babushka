module Babushka
  class Source
    attr_reader :name, :uri, :deps

    delegate :register, :count, :skipped_count, :to => :deps

    def self.pull!
      sources.all? {|source|
        new(source).pull!
      }
    end
    def self.add! uri, opts
      new(uri, opts).add!
    end
    def self.add_external! name, opts = {}
      source = new(:name => name, :uri => external_url_for(name, opts[:from]), :external => true)
      source if source.add!
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
        Source.new(source.delete(:uri), source).remove! opts
      }
    end
    def self.clear! opts = {}
      sources.each {|source|
        Source.new(source.delete(:uri), source).remove! opts
      }
    end

    def self.external_url_for name, from
      {
        :github => "git://github.com/#{name}/babushka-deps.git"
      }[from]
    end

    require 'yaml'
    def self.sources_raw
      File.exists?(sources_yml) &&
      (yaml = YAML.load_file(sources_yml)) &&
      yaml[:sources] ||
      []
    end

    def self.sources
      sources_raw.each {|source| source[:uri] = source[:uri].to_fancypath }
    end

    def self.count
      sources.length
    end

    require 'uri'
    def self.discover_uri_and_type path
      if path.nil?
        [nil, 'implicit']
      elsif path.to_s[/^(git|http|file):\/\//]
        [URI.parse(path.to_s), 'public']
      elsif path.to_s[/^(\w+@)?[a-zA-Z0-9.\-]+:/]
        [path, 'private']
      else
        [path.p, 'local']
      end
    end

    def initialize path, opts = {}
      @uri, @type = self.class.discover_uri_and_type(path)
      @name = opts[:name]
      @external = opts[:external]
      @deps = DepPool.new
    end

    def uri_matches? path
      self.class.discover_uri_and_type(path).first == uri
    end

    def find dep_spec
      deps.for dep_spec
    end

    def prefix
      external? ? external_source_prefix : source_prefix
    end
    def path
      local? ? @uri : prefix / name
    end
    def updated_at
      Time.now - File.mtime(path)
    end
    def description
      "#{name} - #{uri} (updated #{updated_at.round.xsecs} ago)"
    end
    def type
      @type
    end
    def cloned?
      File.directory? path / '.git'
    end
    def external?
      @external
    end
    def local?
      type == 'local'
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
      if !self.class.sources_raw.detect {|s| s[:name] == name }
        log "No such source: #{uri}"
      elsif !in_dir(path) { shell "git ls-files -m -o" }.split("\n").empty?
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
      git uri, :prefix => prefix, :dir => name, :log => true
    end

    def load!
      path.p.glob('**/*.rb').partition {|f|
        f.p.basename == 'templates.rb' or
        f.p.parent.basename == 'templates'
      }.flatten.each {|f|
        DepDefiner.load_context :source => self, :path => f do
          begin
            load f
          rescue Exception => e
            log_error "#{e.backtrace.first}: #{e.message}"
            log "Check #{(e.backtrace.detect {|l| l[f] } || f).sub(/\:in [^:]+$/, '')}."
            debug e.backtrace * "\n"
          end
        end
      }
      log_ok "Loaded #{deps.count}#{" and skipped #{skipped_count}" unless skipped_count.zero?} deps from #{path}."
    end


    private

    def add_source
      if external?
        true
      else
        write_sources self.class.sources_raw.push(yaml_attributes).uniq
      end
    end

    def remove_source
      write_sources self.class.sources_raw - [yaml_attributes]
    end

    def write_sources sources
      File.open self.class.sources_yml, 'w' do |f|
        YAML.dump({:sources => sources}, f)
      end
    end

    def yaml_attributes
      {:name => name, :uri => uri.to_s, :type => type}
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
    def external_source_prefix
      WorkingPrefix / 'external_sources'
    end

  end
end
