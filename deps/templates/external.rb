meta :external do
  accepts_list_for :expects
  accepts_block_for :otherwise

  def cmds_present? cmds
    (cmds || []).all? {|cmd| which cmd }
  end

  template {
    met? {
      returning cmds_present?(expects) || :fail do |result|
        otherwise.call if result == :fail
      end
    }
  }
end
