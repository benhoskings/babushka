module Babushka
  class SourcePool
    SOURCE_DEP_SEPARATOR = ':'

    def current
      @_cached_current ||= [default].concat(core).concat(standard)
    end

    def current_names
      current.map {|source| source.deps.names }.flatten.uniq
    end

    def default
      @_cached_default ||= Source.new(nil, :name => 'default')
    end

    def core
      (@_cached_core ||= [
        Source.new(Path.path / 'deps')
      ]).dup
    end

    def standard
      (@_cached_standard ||= [
        Source.new('./babushka_deps'),
        Source.new('~/.babushka/deps')
      ]).dup
    end

    def dep_for dep_spec, opts = {}
      if dep_spec[/#{SOURCE_DEP_SEPARATOR}/] # If a source was specified, that's where we load from.
        source_name, dep_name = dep_spec.split(SOURCE_DEP_SEPARATOR, 2)
        Source.for_name(source_name).load_and_find(dep_name)
      elsif opts[:from]
        opts[:from].find(dep_spec) || dep_for(dep_spec)
      else # Otherwise, load from the current source (opts[:from]) or the standard set.
        matches = Base.sources.current.map {|source| source.find(dep_spec) }.flatten.compact
        if matches.length > 1
          log "Multiple sources (#{matches.map(&:dep_source).map(&:name).join(',')}) contain a dep called '#{dep_name}'."
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

    def load_core!
      core.map &:load!
    end

    def initialize
      clear!
    end

    def clear! opts = {}
      @sources.each {|s| s.remove! opts } unless @sources.nil?
      @sources = []
    end

    def uncache!
      current.each {|source| source.send :uncache! }
    end

    def count
      @sources.length
    end
  end
end
