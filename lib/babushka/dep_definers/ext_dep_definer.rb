module Babushka
  class ExtDepDefiner < DepDefiner

    def if_missing *cmds, &block
      @cmds, @block = cmds, block
      payload[:met?] = met_block
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
