module Babushka
  class ExtDepRunner < BaseDepRunner

    private

    def cmds_present?
      (@cmds || []).all? {|cmd| which cmd }
    end

  end
end
