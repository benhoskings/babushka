module Babushka
  class DepDefiner
    class UnmeetableDep < DepError
    end

    include RunHelpers

    include AcceptsListFor
    include AcceptsValueFor
    include AcceptsBlockFor

    attr_reader :dependency, :payload, :block

    def name; dependency.name end
    def basename; dependency.basename end
    def load_path; dependency.load_path end

    def set(key, value) vars.set(key, value) end
    def merge(key, value) vars.merge(key, value) end
    def var(name, opts = {}) vars.var(name, opts) end
    def define_var(name, opts = {}) vars.define_var(name, opts) end

    def initialize dep, &block
      @dependency = dep
      @payload = {}
      @block = block
    end

    def define!
      if block.nil?
        # nothing to do
      else
        arity = block.arity
        # ruby 1.8 doesn't support variable numbers of block arguments. Instead, when #arity is -1
        # it means there was no argument block: on 1.8, proc{}.arity == -1, and proc{|| }.arity == 0.
        arity = 0 if arity < 0 && RUBY_VERSION.starts_with?('1.8')

        if dependency.args.length != arity
          raise DepArgumentError, "The dep '#{dependency.name}' requires #{arity} argument#{'s' unless arity == 1}, but #{dependency.args.length} #{dependency.args.length == 1 ? 'was' : 'were'} passed."
        else
          instance_exec *dependency.args, &block
        end
      end
    end

    def result message, opts = {}
      opts[:result].tap {
        dependency.result_message = message
      }
    end

    def met message
      result message, :result => true
    end

    def unmet message
      result message, :result => false
    end

    def unmeetable message
      raise UnmeetableDep, message
    end

    def file_and_line
      get_file_and_line_for(block)
    end

    def file_and_line_for block_name
      get_file_and_line_for send(block_name) if has_block? block_name
    end

    def get_file_and_line_for blk
      blk.inspect.scan(/\#\<Proc\:0x[0-9a-f]+\@([^:]+):(\d+)>/).flatten
    end

    private

    def vars
      Base.task.vars
    end

    def pkg_manager
      BaseHelper
    end

    def on platform, &blk
      if [*chooser].include? platform
        @current_platform = platform
        blk.call.tap {
          @current_platform = nil
        }
      end
    end

    def chooser
      Base.host.match_list
    end

    def chooser_choices
      SystemDefinitions.all_tokens
    end

    def self.source_template
      Dep.base_template
    end

  end
end
