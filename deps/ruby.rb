dep 'ruby' do
  met? {
    in_path? ['ruby >= 1.8.6', 'irb']
  }
  requires_when_unmet {
    on :osx, 'ruby.external'
    otherwise 'ruby.bin'
  }
end

dep 'ruby.bin' do
  installs {
    via [:lenny, :hardy, :lucid], %w[ruby irb ruby1.8-dev libopenssl-ruby]
    via :apt, %w[ruby ruby1.8-dev]
    via :yum, %w[ruby ruby-irb]
    otherwise 'ruby'
  }
  provides %w[ruby irb]
end

dep 'ruby.external' do
  expects 'ruby >= 1.8.6', 'irb'
  otherwise { log_error "This system should already have ruby on it." }
end
