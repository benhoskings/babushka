module Babushka
  class SourcePool

    def current_sources
      @sources
    end

    def default_source
      @default_source ||= source_for(nil, :name => 'default')
    end

    def source_for uri, opts = {}
      if source = current_sources.detect {|source| source.uri_matches?(uri) }
        source
      else
        returning Source.new(uri, opts) do |source|
          @sources.push source
        end
      end
    end

    def all_sources
      [default_source].concat(core_sources) #.concat(cloned_sources)
    end

    def core_sources
      [
        source_for(Path.path / 'deps'),
        source_for('./babushka_deps'),
        source_for('~/.babushka/deps')
      ]
    end

    def cloned_sources
      current_sources.map {|source|
        source_for(source.delete(:uri), source)
      }
    end

    def load_all! opts = {}
      if opts[:first]
        # load_deps_from core_dep_locations.concat([*dep_locations]).concat(Source.all_sources).uniq
      else
        all_sources.map &:load!
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
