dep 'curl.managed' do
  installs {
    via :apt, 'curl', 'libcurl4-openssl-dev'
    via :yum, 'curl'
  }
end
