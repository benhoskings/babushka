module Babushka
  class DepDefiner
    include LogHelpers
    extend LogHelpers
    include ShellHelpers
    extend ShellHelpers
    include PathHelpers
    extend PathHelpers
    include RunHelpers
    extend RunHelpers

    include Prompt::Helpers
    extend Prompt::Helpers
    include VersionOf::Helpers
    extend VersionOf::Helpers

    include AcceptsListFor
    include AcceptsValueFor
    include AcceptsBlockFor

    attr_reader :dependency, :payload, :block

    def name; dependency.name end
    def basename; dependency.basename end
    def load_path; dependency.load_path end

    include Vars::Helpers
    extend Vars::Helpers

    def initialize dep, &block
      @dependency = dep
      @payload = {}
      @block = block
      @loaded, @failed = false, false
    end

    def loaded?; @loaded end
    def failed?; @failed end

    def define!
      unless loaded?
        define_params!
        instance_eval(&block) unless block.nil?
        @loaded, @failed = true, false
      end
      self
    rescue StandardError => e
      raise e if e.is_a?(DepDefinitionError)
      dependency.send(:log_exception_in_dep, e)
      @loaded, @failed = false, true
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
      raise Babushka::UnmeetableDep, message
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

    def define_params!
      dependency.params.each {|param|
        if respond_to?(param)
          raise DepParameterError, "You can't use #{param.inspect} as a parameter (on '#{dependency.name}'), because that's already a method on #{method(param).owner}."
        else
          metaclass.send :define_method, param do
            dependency.args[param] ||= Parameter.new(param)
          end
        end
      }
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
