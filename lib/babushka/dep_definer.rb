module Babushka
  class DepDefiner
    include Shell::Helpers
    include Prompt::Helpers
    include VersionList

    attr_reader :payload, :source_path

    delegate :name, :to => :dependency
    delegate :merge, :var, :define_var, :to => :runner

    def default_blocks
      self.class.default_blocks
    end
    def self.default_blocks
      merged_default_blocks_for self
    end
    def self.merged_default_blocks_for klass
      parent_values = klass == DepDefiner ? {} : merged_default_blocks_for(klass.superclass)
      parent_values.merge(default_blocks_for(klass))
    end
    def self.default_blocks_for klass
      (@@default_blocks ||= Hashish.hash)[klass]
    end

    def self.load_context opts, &block
      @@current_load_source = opts[:source]
      @@current_load_path = opts[:path]
      yield
    ensure
      @@current_load_source = @@current_load_path = nil
    end

    def initialize dep, &block
      @dep = dep
      @payload = {}
      @block = block
      @source_path = self.class.current_load_path.p unless self.class.current_load_path.nil?
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

    def self.current_load_source
      @@current_load_source ||= nil
      @@current_load_source || Base.sources.default
    end

    def self.current_load_path
      @@current_load_path ||= nil
    end

    def self.accepted_blocks
      default_blocks.keys
    end

    def self.accepts_block_for method_name, &default_block
      default_blocks_for(self)[method_name] = default_block
      class_eval %Q{
        def #{method_name} *args, &block
          payload[#{method_name.inspect}] ||= {}
          if block.nil?
            block_for #{method_name.inspect}
          else
            store_block_for #{method_name.inspect}, args, block
          end
        end
      }
      set_up_delegating_for method_name
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
      differentiator = host.differentiator_for payload[task_name].keys
      L{
        debug([
          "#{@dep.name} / #{task_name} not defined",
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

    def store_block_for method_name, args, block
      raise "#{method_name} only accepts args like :on => :linux (as well as a block arg)." unless args.empty? || args.first.is_a?(Hash)

      payload[method_name] ||= {}
      chosen_on = (args.first || {})[:on] || @current_platform || :all
      payload[method_name][chosen_on] = block
    end

    def block_for method_name
      specific_block_for(method_name) or default_task(method_name)
    end

    def specific_block_for method_name
      payload[method_name][(host.match_list & payload[method_name].keys).first] ||
      default_blocks[method_name]
    end

    def self.set_up_delegating_for method_name
      source_template.runner_class.send :delegate, method_name, :to => :definer
    end

    def self.source_template
      Dep::BaseTemplate
    end

  end
end
