dep 'curl.managed' do
  installs {
    via :apt, 'curl', 'libcurl4-openssl-dev'
    via :yum, 'curl'
  }
end

dep 'gettext.managed'

dep 'sudo' do
  requires {
    on :osx, 'sudo.external'
    otherwise 'sudo.managed'
  }
end

dep 'sudo.external' do
  expects 'sudo'
  otherwise {
    log_error "Your system seems to be missing sudo."
  }
end

dep 'sudo.managed'
