src 'macports' do
  requires 'build tools'
  provides 'port'
  prefix '/opt/local'
  source "http://distfiles.macports.org/MacPorts/MacPorts-1.8.0.tar.gz"
  after { log_shell "Running port selfupdate", "port selfupdate", :sudo => true }
end

ext 'apt' do
  if_missing 'apt-get' do
    log "Your system doesn't seem to have Apt installed. Is it Debian-based?"
  end
end
