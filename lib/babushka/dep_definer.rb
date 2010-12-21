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
