dep 'ruby', :template => 'bin' do
  installs {
    via [:lenny, :hardy, :lucid], %w[ruby irb ruby1.8-dev libopenssl-ruby]
    via :apt, %w[ruby ruby1.8-dev]
    via :yum, %w[ruby ruby-irb]
    otherwise 'ruby'
  }
  provides 'ruby >= 1.8.6', 'irb'
end
