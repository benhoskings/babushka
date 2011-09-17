module Babushka
  class DepPool

    def initialize source
      clear!
      @source = source
    end

    def count
      @pool.length
    end
    
    def names
      @pool.keys
    end
    def items
      @pool.values
    end
    def for spec
      spec.respond_to?(:name) ? @pool[spec.name] : @pool[spec]
    end

    def add name, in_opts, block
      if self.for name
        self.for name
      else
        Dep.new name, @source, in_opts, block
      end
    end

    def clear!
      @pool = {}
    end
    def uncache!
      items.each {|i| i.send :uncache! }
    end

    def register item
      raise "Already registered '#{item.name}'." if @pool.has_key?(item.name)
      @pool[item.name] = item
    end

  end
end
