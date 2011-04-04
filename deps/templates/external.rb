meta :external do
  accepts_list_for :expects
  accepts_block_for :otherwise

  template {
    met? {
      (in_path?(expects) || :fail).tap {|result|
        otherwise.call if result == :fail
      }
    }
  }
end
