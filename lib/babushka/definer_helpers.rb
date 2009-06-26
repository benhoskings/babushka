module Babushka
  module DefinerHelpers

    def result message, opts = {}
      returning opts[:result] do
        @dep.unmet_message = message
        log_ok message if opts[:result]
      end
    end

    def   met message; result message, :result => true  end
    def unmet message; result message, :result => false end

  end
end
