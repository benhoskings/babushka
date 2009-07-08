module Babushka
  class ExtDepDefiner < BaseDepDefiner

    def if_missing *cmds, &block
      @cmds, @block = cmds, block
      met? &met_block
    end

    private

    def met_block
      L{
        returning cmds_present? do |result|
          @block.call unless result
        end
      }
    end

    def cmds_present?
      (@cmds || []).all? {|cmd| which cmd }
    end

  end
end
