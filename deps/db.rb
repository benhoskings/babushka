dep 'existing db' do
  setup {
    requires "existing #{var(:db, :default => 'postgres')} db"
  }
end
