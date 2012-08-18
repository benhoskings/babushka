module Babushka
  class SourceError < StandardError
  end
  class SourceLoadError < LoadError
  end
  class Source
    include GitHelpers
    include LogHelpers
    extend LogHelpers
    extend ShellHelpers
    include PathHelpers
    extend PathHelpers

    attr_reader :name, :uri, :deps, :templates

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
      @sources ||= {}
      @sources[default_name_for_uri(path)] ||= begin
        remote = shell "git config remote.origin.url", :cd => path
        if remote.nil?
          Source.new path # local source
        else
          Source.new remote, :name => default_name_for_uri(path) # remote source with custom path
        end
      end
    end

    def self.for_remote name
      Source.new(default_remote_for(name), :name => name)
    end

    def self.default_remote_for name
      "https://github.com/#{name}/babushka-deps.git"
    end

    require 'uri'
    def self.discover_uri_and_type path
      if path.nil?
        [nil, :implicit]
      elsif path.to_s.sub(/^\w+:\/\//, '')[/^[^\/]+[@:]/]
        [path.to_s, :private]
      elsif path.to_s[/^git:\/\//]
        [path.to_s, :public]
      elsif path.to_s[/^\w+:\/\//]
        [path.to_s, :private]
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
      @templates = DepPool.new self
      @loaded = @currently_loading = false
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
        if !@loaded && cloned? && !should_update
          log "Behaviour change: not updating '#{name}'. To update sources as they're loaded, use the new '--update' option.".colorize('on grey')
        end
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
    rescue StandardError => e
      clear!
      raise SourceLoadError.new(e.message).tap {|raised| raised.set_backtrace(e.backtrace) }
    end

    def update!
      if @updated
        debug "Already pulled #{name} (#{uri}) this session."
        true
      elsif @updated == false
        debug "Not updating #{name} (#{uri}) - it's offline."
      elsif Base.sources.local_only?
        debug "Not pulling #{name} (#{uri}) - in local-only mode."
        true
      elsif repo.exists? && repo.dirty?
        log "Not updating #{name} (#{path}) because there are local changes."
      elsif repo.exists? && repo.ahead?
        @updated = false # So the ahead? check doesn't run again, for when there's no network.
        log "Not updating #{name} (#{path}) because it's ahead of origin."
      else
        git(uri, :to => path, :log => true).tap {|result|
          log "Marking #{uri} as offline for this run." unless result
          @updated = result || false
        }
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
