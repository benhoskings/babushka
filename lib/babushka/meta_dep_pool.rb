module Babushka
  class MetaDepPool
    def initialize source
      clear!
      @source = source
    end

    def count
      @template_hash.length
    end
    def names
      @template_hash.keys
    end
    def templates
      @template_hash.values
    end
    def for spec
      spec.respond_to?(:name) ? @template_hash[spec.name] : @template_hash[spec]
    end
    def for_dep dep_spec
      self.for dep_spec.to_s.scan(MetaDepWrapper::TEMPLATE_SUFFIX).flatten.first
    end

    def add name, in_opts, block
      MetaDepWrapper.for name, @source, in_opts, &block
    end

    def clear!
      @template_hash = {}
    end

    def register template
      raise "There is already a registered template called '#{template.name}'." if @template_hash.has_key?(template.name)
      @template_hash[template.name] = template
    end
  end
end
