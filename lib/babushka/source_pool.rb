module Babushka
  class SourcePool

    def current
      @sources
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
      [default].concat(core) #.concat(cloned)
    end

    def core
      [
        source_for(Path.path / 'deps'),
        source_for('./babushka_deps'),
        source_for('~/.babushka/deps')
      ]
    end

    def cloned
      current.map {|source|
        source_for(source.delete(:uri), source)
      }
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

    def clear!
      @sources = []
    end

    def count
      @sources.length
    end
  end
end
