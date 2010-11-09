module Babushka
  class DepDefiner
    include AcceptsListFor
    include AcceptsValueFor
    include AcceptsBlockFor

    attr_reader :payload

    delegate :name, :basename, :to => :dependency
    delegate :merge, :var, :define_var, :to => :runner

    def self.desc str = nil
      @desc = str.strip unless str.nil?
      @desc
    end

    def initialize dep, &block
      @dep = dep
      @payload = {}
      @block = block
    end

    def dependency
      @dep
    end

    def runner
      @dep.runner
    end

    def define_and_process
      process
      instance_eval &@block unless @block.nil?
    end

    def process
      true # overridden in subclassed definers
    end

    def helper name, &block
      runner.metaclass.send :define_method, name do |*args|
        if block.arity == -1
          instance_exec *args, &block
        elsif block.arity != args.length
          raise ArgumentError, "wrong number of args to #{name} (#{args.length} for #{block.arity})"
        else
          instance_exec *args[0...(block.arity)], &block
        end
      end
    end

    def has_task? task_name
      payload[task_name] ||= {}
      !!specific_block_for(task_name)
    end

    def default_task task_name
      differentiator = Base.host.differentiator_for payload[task_name].keys
      L{
        debug([
          "'#{@dep.name}' / #{task_name} not defined",
          "#{" for #{differentiator}" unless differentiator.nil?}",
          {
            :met? => ", moving on",
            :meet => " - nothing to do"
          }[task_name],
          "."
        ].join)
        true
      }
    end


    private

    def on platform, &block
      if platform.in? [*chooser]
        @current_platform = platform
        returning block.call do
          @current_platform = nil
        end
      end
    end

    def self.set_up_delegating_for method_name
      source_template.runner_class.send :delegate, method_name, :to => :definer
    end

    def self.source_template
      Dep::BaseTemplate
    end

  end
end
