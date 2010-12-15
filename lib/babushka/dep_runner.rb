module Babushka
  module DepRunner

    def vars
      Base.task.vars
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

  end
end
