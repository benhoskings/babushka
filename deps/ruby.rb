dep 'ruby' do
  requires 'apt ruby', 'os x ruby'
end

pkg 'apt ruby', :for => :linux do
  installs { via :apt, %w[ruby irb ri rdoc ruby1.8-dev libopenssl-ruby] }
  provides %w[ruby irb ri rdoc]
end

dep 'os x ruby', :for => :osx do
  met? {
    cmds_in_path? ['ruby', 'irb', 'ri', 'rdoc']
  }
end
