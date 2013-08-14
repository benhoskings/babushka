module Babushka
  class SourceError < StandardError
  end
  class SourceLoadError < LoadError
  end
  class Source
    include LogHelpers
    extend LogHelpers
    extend ShellHelpers
    include PathHelpers
    extend PathHelpers

    attr_reader :path, :name, :uri, :deps, :templates

    def self.present
      source_prefix.glob('*').map {|path|
        Source.for_path(path.p)
      }.select {|source|
        source.present?
      }
    end

    def self.for_path path
      @sources ||= {}
      @sources[default_name_for_uri(path)] ||= begin
        remote = shell "git config remote.origin.url", :cd => path
        if remote.nil?
          Source.new path # local source
        else
          Source.new remote, default_name_for_uri(path) # remote source with custom path
        end
      end
    end

    def self.for_remote name
      Source.new(default_remote_for(name), name)
    end

    def self.default_remote_for name
      if name == 'common'
        # This is a special case.
        "https://github.com/benhoskings/common-babushka-deps.git"
      else
        "https://github.com/#{name}/babushka-deps.git"
      end
    end

    require 'uri'
    def type
      if uri.nil?
        :local
      elsif uri.sub(/^\w+:\/\//, '')[/^[^\/]+[@:]/]
        :private
      elsif uri[/^git:\/\//]
        :public
      else
        :private
      end
    end

    def self.default_name_for_uri uri
      if uri.nil?
        nil
      else
        File.basename(uri.to_s).chomp('.git')
      end
    end

    def initialize path, name = nil, uri = nil
      raise ArgumentError, "Sources with nil paths require a name (as the second argument)." if path.nil? && name.nil?
      raise ArgumentError, "The source URI can only be supplied if the source doesn't exist already." if !uri.nil? && !path.nil? && path.p.exists?

      @path = (path || (Source.source_prefix / name)).p
      @name = name || path.p.basename
      @uri = uri || detect_uri

      @deps = DepPool.new self
      @templates = DepPool.new self
      @loaded = @currently_loading = false
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

    def cloneable?
      [:public, :private].include? type
    end

    def cloned?
      cloneable? && File.directory?(path / '.git')
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
        log_block "Adding #{name} from #{uri}" do
          update!
        end
      end
    end

    def clear!
      deps.clear!
      templates.clear!
    end

    def load! should_update = false
      unless @currently_loading
        @currently_loading = true
        update! if cloneable? && (!cloned? || should_update)
        load_deps! unless implicit? # implicit sources can't be loaded.
        @currently_loading = false
      end
    end

    def load_deps!
      unless @loaded
        path.p.glob('**/*.rb').each {|f|
          Base.sources.load_context :source => self, :path => f do
            load f
          end
        }
        debug "Loaded #{deps.count} deps from #{path}."
        @loaded = true
      end
    rescue StandardError, SyntaxError => e
      clear!
      raise SourceLoadError.new(e.message).tap {|raised| raised.set_backtrace(e.backtrace) }
    end

    def update!
      if @updated
        debug "Already pulled #{name} (#{uri}) this session."
        true
      elsif Base.sources.local_only?
        debug "Not pulling #{name} (#{uri}) - in local-only mode."
        true
      elsif @updated == false
        debug "Not updating #{name} (#{uri}) - it's offline."
      elsif repo.exists? && repo.dirty?
        log "Not updating #{name} (#{path}) because there are local changes."
      elsif repo.exists? && repo.ahead?
        @updated = false # So the ahead? check doesn't run again, for when there's no network.
        log "Not updating #{name} (#{path}) because it's ahead of origin."
      else
        GitHelpers.git(uri, :to => path, :log => true).tap {|result|
          log "Marking #{uri} as offline for this run." unless result
          @updated = result || false
        }
      end
    end

    def remove!
      !cloneable? || !path.exists? || path.rm
    end

    private

    def detect_uri
      if present?
        ShellHelpers.shell("git config remote.origin.url", :cd => path)
      else
        self.class.default_remote_for(name)
      end
    end

    def raise_unless_addable!
      present_sources = Base.sources.all_present
      uri_dup_source = present_sources.detect {|s| s.uri == uri && s.name != name }
      name_dup_source = present_sources.detect {|s| s.name == name && s.uri != uri }
      raise SourceError, "There is already a source called '#{name_dup_source.name}' (it contains #{name_dup_source.uri})." unless name_dup_source.nil?
      raise SourceError, "The source #{uri_dup_source.uri} is already present (as '#{uri_dup_source.name}')." unless uri_dup_source.nil?
    end

    def self.source_prefix
      SOURCE_PREFIX.p
    end

    public

    def inspect
      "#<Source:#{object_id} '#{name}' (#{deps.count} dep#{'s' unless deps.count == 1})>"
    end
  end
end
