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

    def add_dep name, params, block
      self.for(name) || begin
        opts = params.extract_options!
        Dep.new name, @source, params, opts, block
      end
    end

    def add_template name, in_opts, block
      DepTemplate.for name, @source, in_opts, &block
    end

    def clear!
      @pool = {}
    end

    def register item
      raise "Already registered '#{item.name}'." if @pool.has_key?(item.name)
      @pool[item.name] = item
    end

  end
end
