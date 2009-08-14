dep 'macports' do
  requires 'build tools'
  merge :versions, :macports => '1.7.1'
  met? { which 'port' }
  meet {
    in_build_dir {
      dmg "http://svn.macports.org/repository/macports/downloads/MacPorts-#{versions[:macports]}/MacPorts-#{versions[:macports]}-#{system_release}-#{system_name}.dmg" do |path|
        log_shell "Installing MacPorts-#{versions[:macports]}", "installer -pkg #{path / "MacPorts-#{versions[:macports]}.pkg"} -target /", :sudo => true
      end
    }
  }
  after { log_shell "Running port selfupdate", "port selfupdate", :sudo => true }
end

ext 'apt' do
  if_missing 'apt-get' do
    log "Your system doesn't seem to have Apt installed. Is it Debian-based?"
  end
end
