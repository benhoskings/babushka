module Babushka
  module DefinerHelpers

    def result message, opts = {}
      returning opts[:result] do
        @dep.unmet_message = message
        log message, :as => (:ok if opts[:result])
      end
    end

    def   met message; result message, :result => true  end
    def unmet message; result message, :result => false end

  end
end
