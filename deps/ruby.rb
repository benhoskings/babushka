dep 'ruby' do
  met? {
    provided? 'ruby >= 1.8.6'
  }
  requires_when_unmet {
    on :osx, 'os x ruby'
    on :ubuntu, 'ruby.managed'
  }
end

dep 'ruby.managed' do
  installs {
    on :maverick, %w[ruby ruby1.8-dev]
    via :apt, %w[ruby irb ruby1.8-dev libopenssl-ruby]
  }
  provides %w[ruby irb]
end

dep 'os x ruby' do
  met? {
    provided? %w[ruby irb]
  }
end
