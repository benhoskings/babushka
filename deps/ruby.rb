dep 'ruby', :template => 'bin' do
  installs {
    via [:lenny, :hardy, :lucid], %w[ruby irb libopenssl-ruby]
    via :apt, %w[ruby]
    via :yum, %w[ruby ruby-irb]
    via :zypper, %w[ruby]
    otherwise 'ruby'
  }
  provides 'ruby >= 1.8.6', 'irb'
end
