module Babushka
  class SourcePool
    SOURCE_DEP_SEPARATOR = ':'

    def current
      @_cached_current ||= default.concat(standard)
      @_cached_current.dup
    end

    def default
      [anonymous, core].dup
    end

    def current_names
      current.map {|source| source.deps.names }.flatten.uniq
    end

    def all_present
      current.concat(Source.present)
    end

    def anonymous
      @_cached_anonymous ||= Source.new(nil, :name => 'anonymous')
    end
    def core
      @_cached_core ||= Source.new(Path.path / 'deps', :name => 'core')
    end
    def current_dir
      @_cached_current_dir ||= Source.new('./babushka-deps', :name => 'current dir')
    end
    def personal
      @_cached_personal ||= Source.new('~/.babushka/deps', :name => 'personal')
    end

    def standard
      [current_dir, personal]
    end

    def source_for name
      all_present.detect {|source| source.name == name } || Source.for_remote(name)
    end

    def dep_for dep_spec, opts = {}
      if dep_spec.is_a?(Dep)
        dep_spec
      elsif dep_spec.is_a?(VersionOf)
        dep_for dep_spec.to_s, opts
      elsif dep_spec[/#{SOURCE_DEP_SEPARATOR}/] # If a source was specified, that's where we load from.
        source_name, dep_name = dep_spec.split(SOURCE_DEP_SEPARATOR, 2)
        source_for(source_name).find(dep_name)
      elsif opts[:from]
        opts[:from].find(dep_spec) || dep_for(dep_spec)
      else # Otherwise, load from the current source (opts[:from]) or the standard set.
        matches = Base.sources.current.map {|source| source.find(dep_spec) }.flatten.compact
        if matches.length > 1
          log "Multiple sources (#{matches.map(&:dep_source).map(&:name).join(',')}) contain a dep called '#{dep_spec}'."
        else
          matches.first
        end
      end
    end

    def template_for template_spec, opts = {}
      if template_spec.nil?
        nil
      elsif template_spec[/#{SOURCE_DEP_SEPARATOR}/] # If a source was specified, that's where we load from.
        source_name, template_name = template_spec.split(SOURCE_DEP_SEPARATOR, 2)
        source_for(source_name).find_template(template_name)
      elsif opts[:from]
        opts[:from].find_template(template_spec) || template_for(template_spec)
      else
        matches = Base.sources.default.map {|source| source.find_template(template_spec) }.flatten.compact
        if matches.length > 1
          log "Multiple sources (#{matches.map(&:source).map(&:name).join(',')}) contain a template called '#{template_name}'."
        else
          matches.first
        end
      end
    end

    def load_all! opts = {}
      if opts[:first]
        # load_deps_from core_dep_locations.concat([*dep_locations]).concat(Source.all).uniq
      else
        current.map &:load!
      end
    end

    def update!
      all_present.select {|source|
        source.cloneable?
      }.tap {|sources|
        log "Updating #{sources.length} source#{'s' unless sources.length == 1}."
      }.map {|source|
        source.update!
      }.all?
    end

    def list!
      log_table(
        ['Name', 'Source path', 'Type', 'Last updated'],
        Source.present.tap {|sources|
          log "There #{sources.length == 1 ? 'is' : 'are'} #{sources.length} source#{'s' unless sources.length == 1} in #{Source.source_prefix}:"
          log ''
        }.map(&:description_pieces)
      )
    end

    def uncache!
      current.each {|source| source.send :uncache! }
    end

    def local_only?
      @local_only
    end

    def local_only &block
      previously = @local_only
      @local_only = true
      yield
    ensure
      @local_only = previously
    end

    def load_context context, &block
      (@load_contexts ||= []).push context
      yield
    ensure
      @load_contexts.pop
    end

    def current_load_source
      current_load_context[:source] || Base.sources.anonymous
    end
    def current_load_path
      current_load_context[:path]
    end
    def current_load_opts
      current_load_context[:opts] || {}
    end

    private

    def current_load_context
      (@load_contexts ||= []).last || {}
    end

  end
end
