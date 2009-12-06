module Babushka
  class DepPool

    attr_reader :skipped_count

    def initialize
      clear!
      @skipped = 0
    end

    def count
      @dep_hash.length
    end
    
    def names
      @dep_hash.keys
    end
    def deps
      @dep_hash.values
    end
    def for name
      @dep_hash[name]
    end

    def add name, in_opts, block, definer_class, runner_class
      if self.for name
        @skipped += 1
        self.for name
      else
        Dep.new name, in_opts, block, definer_class, runner_class
      end
    end

    def clear!
      @dep_hash = {}
    end
    def uncache!
      deps.each {|dep| dep.send :uncache! }
    end

    def register dep
      raise "There is already a registered dep called '#{dep.name}'." if @dep_hash.has_key?(dep.name)
      @dep_hash[dep.name] = dep
    end

  end
end
