module Babushka
  class Source
    attr_reader :name, :uri, :type, :deps

    delegate :register, :count, :skipped_count, :uncache!, :to => :deps

    def self.present
      source_prefix.glob('*').map(&:p).select {|path|
        path.directory?
      }.map {|path|
        Source.for_path path
      }.select {|source|
        source.present?
      }
    end

    extend Babushka::Shell::Helpers
    def self.for_path path
      path = path.p
      if !path.directory?
        raise ArgumentError, "The path #{path} isn't a directory."
      else
        remote = in_dir(path) { shell "git config remote.origin.url" }
        if remote.nil?
          Source.new path # local source
        else
          Source.new remote, :path => path # remote source with custom path
        end
      end
    end

    def self.for_name name
      present.detect {|source| source.name == name } || Source.new(default_remote_for(name, :github), :name => name)
    end

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

    def self.default_remote_for name, from
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
        [nil, :implicit]
      elsif path.to_s[/^(git|http|file):\/\//]
        [URI.parse(path.to_s), :public]
      elsif path.to_s[/^(\w+@)?[a-zA-Z0-9.\-]+:/]
        [path, :private]
      else
        [path.p, :local]
      end
    end

    def self.default_name_for_uri uri
      if uri.nil?
        nil
      else
        File.basename(uri.to_s).chomp('.git')
      end
    end

    def initialize path, opts = {}
      raise ArgumentError, "Source.new options must be passed as a hash, not as #{opts.inspect}." unless opts.is_a?(Hash)
      @uri, @type = self.class.discover_uri_and_type(path)
      @name = opts[:name] || self.class.default_name_for_uri(@uri)
      @external = opts[:external]
      @deps = DepPool.new self
    end

    def uri_matches? path
      self.class.discover_uri_and_type(path).first == uri
    end

    def find dep_spec
      load!
      deps.for(dep_spec).tap {|o| debug "#{name} (#{count} deps): #{o.inspect}" }
    end

    def prefix
      external? ? self.class.external_source_prefix : self.class.source_prefix
    end
    def path
      if implicit? || local?
        @uri
      else
        prefix / name
      end
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
    def cloneable?
      [:public, :private].include? type
    end
    def cloned?
      File.directory? path / '.git'
    end
    def present?
      cloneable? ? cloned? : path.exists?
    end
    def external?
      @external
    end
    def local?
      type == :local
    end
    def implicit?
      type == :implicit
    end

    def == other
      [:name, :uri, :type].all? {|method_name| other.respond_to? method_name } &&
      name == other.name &&
      uri == other.uri &&
      type == other.type
    end

    def add!
      if !cloneable?
        log "Nothing to add for #{name}."
      else
        raise_unless_addable!
        log_block "Adding #{name}" do
          pull!
        end
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

    def load!
      pull! if cloneable?
      load_deps! unless implicit? # implicit sources can't be loaded.
    end

    def load_deps!
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

    def inspect
      "#<Babushka::Source @name=#{name.inspect}, @type=#{type.inspect}, @uri=#{uri.inspect}, @deps.count=#{deps.count}>"
    end

    private

    include Shell::Helpers
    include GitHelpers
    def pull!
      git uri, :prefix => prefix, :dir => name, :log => true
    end

    def raise_unless_addable!
      uri_dup_source = Base.sources.current.detect {|s|
        "#{s.uri}==#{uri}".taph
        s.uri == uri
      }.taph
      name_dup_source = Base.sources.current.detect {|s|
        "#{s.name}==#{name}".taph
        s.name == name
      }.taph
      if uri_dup_source != name_dup_source
        raise "There is already a source called '#{name_dup_source.name}' (it contains #{name_dup_source.uri})." unless name_dup_source.nil?
        raise "The source #{uri_dup_source.uri} is already present (as '#{uri_dup_source.name}')." unless uri_dup_source.nil?
      end
    end

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
    def self.source_prefix
      Path.path / 'sources'
    end
    def self.external_source_prefix
      WorkingPrefix / 'external_sources'
    end

  end
end
