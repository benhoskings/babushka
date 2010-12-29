module Babushka
  class SourceError < StandardError
  end
  class Source
    include GitHelpers
    include LogHelpers
    include PathHelpers
    extend PathHelpers

    attr_reader :name, :uri, :repo, :type, :deps, :templates

    delegate :count, :skipped_count, :uncache!, :to => :deps

    def self.present
      source_prefix.glob('*').map(&:p).select {|path|
        path.directory?
      }.map {|path|
        Source.for_path path
      }.select {|source|
        source.present?
      }
    end

    def self.for_path path
      path = path.p
      if !path.directory?
        raise ArgumentError, "The path #{path} isn't a directory."
      else
        remote = in_dir(path) { shell "git config remote.origin.url" }
        if remote.nil?
          Source.new path # local source
        else
          Source.new remote, :name => path.basename # remote source with custom path
        end
      end
    end

    def self.for_remote name
      Source.new(default_remote_for(name, :github), :name => name)
    end

    def self.default_remote_for name, from
      {
        :github => "git://github.com/#{name}/babushka-deps.git"
      }[from]
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
      @name = (opts[:name] || self.class.default_name_for_uri(@uri)).to_s
      @deps = DepPool.new self
      @templates = MetaDepPool.new self
    end

    def uri_matches? path
      self.class.discover_uri_and_type(path).first == uri
    end

    def find dep_spec
      load!
      deps.for(dep_spec)
    end

    def find_template template_spec
      load!
      templates.for(template_spec)
    end

    def prefix
      self.class.source_prefix
    end
    def path
      if implicit? || local?
        @uri
      else
        prefix / name
      end
    end

    def repo
      @repo ||= GitRepo.new(path) if cloneable?
    end

    def updated_at
      Time.now - File.mtime(path)
    end
    def description_pieces
      [
        name,
        uri.to_s,
        type,
        ("#{updated_at.round.xsecs} ago" if cloneable?)
      ]
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
          update!
        end
      end
    end

    def load!
      unless @currently_loading
        @currently_loading = true
        update! if cloneable?
        load_deps! unless implicit? # implicit sources can't be loaded.
        @currently_loading = false
      end
    end

    def load_deps!
      unless @loaded
        path.p.glob('**/*.rb').each {|f|
          Base.sources.load_context :source => self, :path => f, :opts => {:lazy => true} do
            begin
              load f
            rescue Exception => e
              log_error "#{e.backtrace.first}: #{e.message}"
              log "Check #{(e.backtrace.detect {|l| l[f] } || f).sub(/\:in [^:]+$/, '')}."
              debug e.backtrace * "\n"
            end
          end
        }
        log_ok "Loaded #{deps.count}#{" and skipped #{skipped_count}" unless skipped_count.zero?} deps from #{path}." unless deps.count.zero?
        @loaded = true
      end
    end

    def define_deps!
      Base.sources.load_context :source => self do
        deps.define_deps!
      end
    end

    def inspect
      "#<Babushka::Source @name=#{name.inspect}, @type=#{type.inspect}, @uri=#{uri.inspect}, @deps.count=#{deps.count}>"
    end

    def update!
      if @updated
        debug "Already pulled #{name} (#{uri}) this session."
        true
      elsif Base.sources.local_only?
        debug "Not pulling #{name} (#{uri}) - in local-only mode."
        true
      elsif repo.exists? && repo.dirty?
        log "Not updating #{name} (#{path}) because there are local changes."
      elsif repo.exists? && repo.ahead?
        log "Not updating #{name} (#{path}) because it's ahead of origin."
      else
        @updated = git uri, :to => path, :log => true
      end
    end

    private

    def raise_unless_addable!
      present_sources = Base.sources.all_present
      uri_dup_source = present_sources.detect {|s| s.uri == uri && s.name != name }
      name_dup_source = present_sources.detect {|s| s.name == name && s.uri != uri }
      raise SourceError, "There is already a source called '#{name_dup_source.name}' (it contains #{name_dup_source.uri})." unless name_dup_source.nil?
      raise SourceError, "The source #{uri_dup_source.uri} is already present (as '#{uri_dup_source.name}')." unless uri_dup_source.nil?
    end

    def self.source_prefix
      SourcePrefix.p
    end

    public

    def inspect
      "#<Source:#{object_id} '#{name}' (#{deps.count} dep#{'s' unless deps.count == 1})>"
    end
  end
end
