dep 'ruby' do
  requires {
    on :osx, 'os x ruby'
    on :ubuntu, 'apt ruby'
  }
end

pkg 'apt ruby' do
  installs { via :apt, %w[ruby irb ruby1.8-dev libopenssl-ruby] }
  provides %w[ruby irb]
end

dep 'os x ruby' do
  met? {
    provided? %w[ruby irb]
  }
end
