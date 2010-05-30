module Babushka
  class SourcePool

    def current
      @sources
    end

    def current_names
      current.map {|source| source.deps.names }.flatten.uniq
    end

    def default
      @default_source ||= source_for(nil, :name => 'default')
    end

    def source_for uri, opts = {}
      if source = current.detect {|source| source.uri_matches?(uri) }
        source
      else
        returning Source.new(uri, opts) do |source|
          @sources.push source
        end
      end
    end

    def all
      [default].concat(core).concat(Source.present)
    end

    def core
      [
        source_for(Path.path / 'deps'),
        source_for('./babushka_deps'),
        source_for('~/.babushka/deps')
      ]
    end

    def load_all! opts = {}
      if opts[:first]
        # load_deps_from core_dep_locations.concat([*dep_locations]).concat(Source.all).uniq
      else
        all.map &:load!
      end
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
