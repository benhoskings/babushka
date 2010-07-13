meta :external do
  accepts_list_for :expects
  accepts_block_for :otherwise

  template {
    helper :cmds_present? do |cmds|
      (cmds || []).all? {|cmd| which cmd }
    end
    met? {
      returning cmds_present?(expects) || :fail do |result|
        otherwise.call if result == :fail
      end
    }
  }
end
