module Babushka
  class SourcePool

    def current
      @sources
    end

    def current_names
      current.map {|source| source.deps.names }.flatten.uniq
    end

    def default
      @default_source ||= Source.new(nil, :name => 'default')
    end

    def all
      [default].concat(core).concat(Source.present)
    end

    def core
      [
        Source.new(Path.path / 'deps'),
        Source.new('./babushka_deps'),
        Source.new('~/.babushka/deps')
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
