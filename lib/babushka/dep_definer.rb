module Babushka
  class DepDefiner
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
      file, line = caller.first.split(':', 2)
      line = line.to_i
      metaclass.send :define_method, name do |*args|
        log_error "#helper is deprecated. Design improvements mean that it's not required; you\n" +
          "can just use a standard method instead, like so:\n" +
          "  (at #{file}:#{line})\n" +
          "  def #{name} #{('a'..'z').to_a[0...(block.arity)].join(', ')}\n" +
          "    ...\n" +
          "  end"
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
        dependency.unmet_message = message
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

    def file_and_line
      get_file_and_line_for(@block)
    end

    def file_and_line_for block_name
      get_file_and_line_for send(block_name) if has_block? block_name
    end

    def get_file_and_line_for block
      block.inspect.scan(/\#\<Proc\:0x[0-9a-f]+\@([^:]+):(\d+)>/).flatten
    end

    private

    def vars
      Base.task.vars
    end

    def pkg_manager
      BaseHelper
    end

    def on platform, &block
      if platform.in? [*chooser]
        @current_platform = platform
        returning block.call do
          @current_platform = nil
        end
      end
    end

    def chooser
      Base.host.match_list
    end

    def chooser_choices
      Base.host.all_tokens
    end

    def self.source_template
      Dep.base_template
    end

  end
end
