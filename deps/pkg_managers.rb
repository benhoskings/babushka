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

dep 'pacman', :template => 'external' do
  expects 'pacman'
  otherwise {
    log "You seem to be running Arch Linux, but are missing the Pacman package manager. Something is very, very wrong here."
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
    before {
      # Don't edit sources.list unless we know how to edit it for this debian flavour and version.
      Babushka::AptHelper.source_for_system and Babushka::Base.host.name
    }
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
  requires 'binary.homebrew', 'build tools'
end

dep 'yum', :template => 'external' do
  expects 'yum'
  otherwise {
    log "Your system doesn't seem to have Yum installed. Is it Redhat-based?"
  }
end

dep 'npm' do
  requires 'nodejs.src'
  met? { which 'npm' }
  meet {
    log_shell "Installing npm", "curl http://npmjs.org/install.sh | #{'sudo' unless which('node').p.writable?} sh"
  }
end

dep 'nodejs.src' do
  source 'git://github.com/joyent/node.git'
  provides 'node >= 0.4', 'node-waf'
end

dep 'pip' do
  requires {
    on :osx, 'pip.src'
    otherwise 'pip.managed'
  }
end

dep 'pip.managed' do
  installs 'python-pip'
end

dep 'pip.src' do
  source 'http://pypi.python.org/packages/source/p/pip/pip-0.8.3.tar.gz'
  process_source {
    log_shell "Installing pip", "python setup.py install", :sudo => !which('python').p.writable?
  }
end

dep 'pkgsrc', :template => 'external' do
  expects 'pkg_radd'
  otherwise {
    log "You seem to be running DragonflyBSD ot NETBSD, but are missing the pkgsrc package manager. Something is very, very wrong here."
  }
end
