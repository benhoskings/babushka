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
      }
    end

    def self.for_path path
      source = Source.new(path)
      @sources ||= {}
      @sources[source.name] ||= source
    end

    def self.for_remote name
      Source.new(nil, name, default_remote_for(name))
    end

    def self.default_remote_for name
      if name == 'common'
        # This is a special case.
        "https://github.com/benhoskings/common-babushka-deps.git"
      else
        "https://github.com/#{name}/babushka-deps.git"
      end
    end

    def initialize path, name = nil, uri = nil
      raise ArgumentError, "Sources with nil paths require a name (as the second argument)." if path.nil? && name.nil?
      raise ArgumentError, "The source URI can only be supplied if the source doesn't exist already." if !uri.nil? && !path.nil? && path.p.exists?
      init
      @path, @name, @uri = path.try(:p), name, uri
    end

    def path
      @path ||= (Source.source_prefix / name).p
    end

    def name
      @name ||= path.basename.to_s
    end

    def uri
      @uri ||= detect_uri
    end

    def present?
      path.exists?
    end

    def type
      uri.nil? ? :local : :remote
    end

    def implicit?
      type == :implicit
    end

    def local?
      type == :local
    end

    def remote?
      type == :remote
    end

    def repo
      @repo ||= Babushka::GitRepo.new(path)
    end

    def repo?
      repo.exists? && (repo.root == path)
    end

    def updated_at
      Time.now - File.mtime(path)
    end

    def description_pieces
      [
        name,
        uri.to_s,
        type,
        ("#{updated_at.round.xsecs} ago" if remote?)
      ]
    end

    def == other
      [:name, :uri, :type].all? {|method_name| other.respond_to? method_name } &&
      name == other.name &&
      uri == other.uri &&
      type == other.type
    end

    def find dep_spec
      load!
      deps.for(dep_spec)
    end

    def find_template template_spec
      load!
      templates.for(template_spec)
    end

    def add!
      if !remote?
        log "Nothing to add for #{name}."
      else
        raise_unless_addable!
        update!
      end
    end

    def clear!
      deps.clear!
      templates.clear!
    end

    def load! should_update = false
      unless @currently_loading
        @currently_loading = true
        update! if remote? && (!repo? || should_update)
        load_deps! unless implicit? # implicit sources can't be loaded.
        @currently_loading = false
      end
    end

    def load_deps!
      unless @loaded
        path.p.glob('**/*.rb').each {|f|
          Base.sources.load_context :source => self, :path => f do
            load f, true
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

    private

    def init
      @deps = DepPool.new self
      @templates = DepPool.new self
      @loaded = @currently_loading = false
    end

    def detect_uri
      if present? && repo?
        ShellHelpers.shell("git config remote.origin.url", :cd => path)
      end
    end

    def raise_unless_addable!
      present_sources = Base.sources.all_present
      uri_dup_source = present_sources.detect {|s| s.uri == uri && s.name != name }
      name_dup_source = present_sources.detect {|s| s.name == name && s.uri != uri }
      raise SourceError, "There is already a source called '#{name_dup_source.name}' at #{name_dup_source.path}." unless name_dup_source.nil?
      raise SourceError, "The remote #{uri_dup_source.uri} is already present on '#{uri_dup_source.name}', at #{uri_dup_source.path}." unless uri_dup_source.nil?
    end

    def self.source_prefix
      SOURCE_PREFIX.p
    end

    public

    def inspect
      "#<Source:#{object_id} '#{name}' (#{path} <- #{uri}) (#{deps.count} dep#{'s' unless deps.count == 1})>"
    end
  end
end
