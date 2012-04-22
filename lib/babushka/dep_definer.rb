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
      unless loaded? || failed?
        define_elements!
        @loaded, @failed = true, false
      end
      self
    rescue StandardError => e
      @loaded, @failed = false, true
      raise e
    end

    def invoke task_name
      define! unless loaded?
      instance_eval &send(task_name) unless failed?
    end

    def result message, opts = {}
      opts[:result].tap {
        dependency.result_message = message
      }
    end

    def met message
      deprecated! "2012-06-22", "a truthy return value from met?{} (maybe using #log_ok)"
      result message, :result => true
    end

    def unmet message
      deprecated! "2012-06-22", "a falsey return value from met?{} (maybe using #log)"
      result message, :result => false
    end

    def unmeetable message
      deprecated! "2012-06-22", "#unmeetable!"
      raise Babushka::UnmeetableDep, message
    end

    def unmeetable! message
      raise Babushka::UnmeetableDep, message
    end

    def source_location
      get_source_location_for(block)
    end

    def source_location_for block_name
      get_source_location_for send(block_name) if has_block? block_name
    end

    def get_source_location_for blk
      if blk.respond_to?(:source_location) # Not present on cruby-1.8.
        blk.source_location
      else
        blk.inspect.scan(/\#\<Proc\:0x[0-9a-f]+\@([^:]+):(\d+)>/).flatten
      end
    end

    private

    def define_elements!
      debug "(defining #{dependency.name} against #{dependency.template.contextual_name})"
      define_params!
      instance_eval(&block) unless block.nil?
    end

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
      UnknownPkgHelper
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
      Babushka.host.match_list
    end

    def chooser_choices
      SystemDefinitions.all_tokens
    end

    def self.source_template
      Dep.base_template
    end

  end
end
