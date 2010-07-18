dep 'macports.src' do
  requires 'build tools'
  provides 'port'
  prefix '/opt/local'
  source "http://distfiles.macports.org/MacPorts/MacPorts-1.8.0.tar.gz"
  after { log_shell "Running port selfupdate", "port selfupdate", :sudo => true }
end

dep 'apt', :template => 'external' do
  requires {
    on :ubuntu, 'main.apt_source', 'universe.apt_source'
    on :debian, 'main.apt_source'
  }
  expects 'apt-get'
  otherwise {
    log "Your system doesn't seem to have Apt installed. Is it Debian-based?"
  }
end

meta :apt_source do
  accepts_list_for :source_name
  template {
    met? {
      source_name.all? {|name|
        grep(/^deb .* #{Babushka::Base.host.name} (\w+ )*#{Regexp.escape(name.to_s)}/, '/etc/apt/sources.list')
      }
    }
    before { Babushka::AptHelper.source_for_system }
    meet {
      source_name.each {|name|
        append_to_file "deb #{Babushka::AptHelper.source_for_system} #{Babushka::Base.host.name} #{name}", '/etc/apt/sources.list', :sudo => true
      }
    }
    after { Babushka::AptHelper.update_pkg_lists }
  }
end

dep 'main.apt_source' do
  source_name 'main'
end

dep 'universe.apt_source' do
  source_name 'universe'
end

dep 'homebrew' do
  requires 'homebrew binary in place', 'build tools'
end

dep 'yum', :template => 'external' do
  expects 'yum'
  otherwise {
    log "Your system doesn't seem to have Yum installed. Is it Redhat-based?"
  }
end
