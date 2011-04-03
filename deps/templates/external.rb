meta :external do
  accepts_list_for :expects
  accepts_block_for :otherwise

  template {
    met? {
      returning in_path?(expects) || :fail do |result|
        otherwise.call if result == :fail
      end
    }
  }
end
