dep 'curl.managed' do
  installs {
    via :apt, 'curl'
    via :yum, 'curl'
  }
end
