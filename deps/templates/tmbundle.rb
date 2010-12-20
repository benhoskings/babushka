meta :tmbundle, :for => :osx do
  accepts_list_for :source

  template {
    requires 'benhoskings:TextMate.app'
    helper :path do
      '~/Library/Application Support/TextMate/Bundles' / name
    end
    met? { path.dir? }
    before { shell "mkdir -p '#{path.parent}'" }
    meet {
      source.each {|uri| git uri, :to => path }
    }
    after { shell %Q{osascript -e 'tell app "TextMate" to reload bundles'} }
  }
end
