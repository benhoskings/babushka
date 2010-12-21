meta :tmbundle, :for => :osx do
  accepts_list_for :source

  def path
    '~/Library/Application Support/TextMate/Bundles' / name
  end

  template {
    requires 'benhoskings:TextMate.app'
    met? { path.dir? }
    before { shell "mkdir -p #{path.parent}" }
    meet {
      source.each {|uri| git uri, :to => path }
    }
    after { shell %Q{osascript -e 'tell app "TextMate" to reload bundles'} }
  }
end
