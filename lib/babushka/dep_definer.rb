module Babushka
  class DepDefiner
    include PromptHelpers
    include RunHelpers

    include AcceptsListFor
    include AcceptsValueFor
    include AcceptsBlockFor

    attr_reader :payload, :dependency

    delegate :name, :basename, :load_path, :to => :dependency

    def initialize dep, &block
      @dependency = dep
      @payload = {}
      @block = block
    end

    def define!
      instance_eval &@block unless @block.nil?
    end

    delegate :var, :set, :merge, :define_var, :to => :vars

    def helper name, &block
      metaclass.send :define_method, name do |*args|
        if block.arity == -1
          instance_exec *args, &block
        elsif block.arity != args.length
          raise ArgumentError, "wrong number of args to #{name} (#{args.length} for #{block.arity})"
        else
          instance_exec *args[0...(block.arity)], &block
        end
      end
    end

    def result message, opts = {}
      returning opts[:result] do
        @dep.unmet_message = message
      end
    end

    def met message
      result message, :result => true
    end

    def unmet message
      result message, :result => false
    end

    def fail_because message
      log message
      :fail
    end


    private

    def vars
      Base.task.vars
    end

    def on platform, &block
      if platform.in? [*chooser]
        @current_platform = platform
        returning block.call do
          @current_platform = nil
        end
      end
    end

    def self.source_template
      Dep.base_template
    end

  end
end
