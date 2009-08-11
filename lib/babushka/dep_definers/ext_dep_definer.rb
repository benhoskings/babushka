module Babushka
  class ExtDepDefiner < BaseDepDefiner

    def if_missing *cmds, &block
      set :cmds, cmds
      set :block, block
      met? &met_block
    end

    private

    def met_block
      L{
        returning cmds_present? || :fail do |result|
          block.call if result == :fail
        end
      }
    end

  end
end
