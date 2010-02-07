meta :tmbundle, :for => :osx do
  accepts_list_for :source
  accepts_list_for :bundle_name, :name

  template {
    requires 'TextMate.app'
    helper :path do
      '~/Library/Application Support/TextMate/Bundles' / bundle_name
    end
    met? { path.dir? }
    before { shell "mkdir -p #{path.parent}" }
    meet { git source, :dir => bundle_name.first, :prefix => path.parent }
    after { shell %Q{osascript -e 'tell app "TextMate" to reload bundles'} }
  }
end
