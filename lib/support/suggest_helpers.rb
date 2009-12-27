module Babushka
  class Suggest
    module Helpers
      include PromptHelpers

      def suggest_value_for typo, choices
        if (possible_matches = choices.similar_to typo.to_s).empty?
          nil # nothing to suggest
        elsif possible_matches.length == 1
          confirm "#{"Did you mean".colorize('grey')} '#{possible_matches.first}'#{"?".colorize('grey')}" do
            possible_matches.first
          end or false
        else
          log "Similar: #{possible_matches.map {|d| "'#{d}'" }.join(', ')}"
          prompt_for_value("Did you mean any of those".colorize('grey'), :default => possible_matches.first)
        end
      end

    end
  end
end