module Babushka
  class DepDefiner
    class UnmeetableDep < DepError
    end

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
        block.call.tap {
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
