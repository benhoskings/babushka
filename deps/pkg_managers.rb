ext_dep 'macports' do
  requires 'build tools'
  if_missing 'port' do
    log_and_open "Install the MacPorts release for your system, and then run Babushka again.",
      "http://www.macports.org/install.php"
  end
end

ext_dep 'apt' do
  if_missing 'apt-get' do
    log "Your system doesn't seem to have Apt installed. Is it Debian-based?"
  end
end
