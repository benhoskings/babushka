module Babushka
  class MetaDepWrapper
    INVALID_NAMES = %w[base]

    def self.wrappers
      @wrappers ||= Hashish.hash
    end

    def self.for supplied_name, opts, &block
      name = supplied_name.to_s.downcase
      if name.to_s.blank?
        raise ArgumentError, "You can't define a meta dep with a blank name."
      elsif name.in? INVALID_NAMES
        raise ArgumentError, "You can't use '#{name}' for a meta dep name, because it's reserved."
      elsif Babushka.const_defined?("#{name.to_s.camelize}DepDefiner") || Babushka.const_defined?("#{name.to_s.camelize}DepRunner")
        raise ArgumentError, "A meta dep called '#{name}' has already been defined."
      else
        new name, opts, &block
      end
    end

    attr_reader :name, :opts, :definer_class, :runner_class

    def initialize name, opts, &block
      @name = name.to_sym
      @opts = opts
      @block = block
      @definer_class = build_definer block
      @runner_class = build_runner
      define_dep_helper
      self.class.wrappers[@name] = self
    end

    def build_definer block
      Babushka.const_set "#{name.to_s.camelize}DepDefiner", Class.new(MetaDepDefiner, &block)
    end

    def build_runner
      Babushka.const_set "#{name.to_s.camelize}DepRunner", Class.new(MetaDepRunner)
    end

    def define_dep name, opts, &block
      Dep.pool.add name, opts, block, definer_class, runner_class
    end

    def define_dep_helper
      file, line = caller.first.split(':', 2)
      line = line.to_i
      Object.class_eval <<-EOS, file, line
        def #{name} name, opts = {}, &block
          MetaDepWrapper.wrappers[#{name.inspect}].define_dep name, opts, &block
        end
      EOS
    end

  end
end
