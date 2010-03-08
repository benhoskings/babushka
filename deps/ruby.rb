dep 'ruby' do
  requires {
    on :osx, 'os x ruby'
    on :ubuntu, 'apt ruby'
  }
end

pkg 'apt ruby' do
  installs { via :apt, %w[ruby irb rdoc ruby1.8-dev libopenssl-ruby] }
  provides %w[ruby irb rdoc]
end

dep 'os x ruby' do
  met? {
    provided? ['ruby', 'irb', 'ri', 'rdoc']
  }
end
