module Babushka
  class ExtDepDefiner < BaseDepDefiner

    def if_missing *cmds, &block
      met? {
        returning cmds_present?(cmds) || :fail do |result|
          block.call if result == :fail
        end
      }
    end

  end
end
