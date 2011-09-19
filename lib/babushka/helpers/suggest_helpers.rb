module Babushka
  module SuggestHelpers
    def suggest_value_for typo, choices
      if (possible_matches = choices.similar_to typo.to_s).empty?
        nil # nothing to suggest
      elsif possible_matches.length == 1
        Prompt.confirm "#{"Did you mean".colorize('grey')} '#{possible_matches.first}'#{"?".colorize('grey')}" do
          possible_matches.first
        end or false
      else
        log "Similar: #{possible_matches.map {|d| "'#{d}'" }.join(', ')}"
        Prompt.get_value("Did you mean any of those".colorize('grey'), :default => possible_matches.first)
      end
    end
  end
end