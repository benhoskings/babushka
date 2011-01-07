meta :tmbundle, :for => :osx do
  accepts_value_for :source

  def path
    '~/Library/Application Support/TextMate/Bundles' / name
  end

  template {
    requires 'benhoskings:TextMate.app'
    met? { path.dir? }
    before { shell "mkdir -p '#{path.parent}'" }
    meet { git source, :to => path }
    after { log_shell "Telling TextMate to reload bundles", %Q{osascript -e 'tell app "TextMate" to reload bundles'} }
  }
end
