dep 'package manager', :cmd do
  met? {
    in_path?(cmd).tap {|result|
      unmeetable! "The package manager's binary, #{cmd}, isn't in the $PATH." unless result
    }
  }
end

dep 'macports.src' do
  requires 'build tools'
  provides 'port'
  prefix '/opt/local'
  source "http://distfiles.macports.org/MacPorts/MacPorts-1.8.0.tar.gz"
  after { log_shell "Running port selfupdate", "port selfupdate", :sudo => true }
end

dep 'apt', :template => 'external' do
  requires {
    on :ubuntu, 'apt source'.with(:repo => 'main'), 'apt source'.with(:repo => 'universe')
    on :debian, 'apt source'.with(:repo => 'main')
  }
  expects 'apt-get'
  otherwise {
    log "Your system doesn't seem to have Apt installed. Is it Debian-based?"
  }
end

dep 'homebrew' do
  requires 'binary.homebrew', 'build tools'
end

dep 'npm' do
  requires 'nodejs.src'
  met? { which 'npm' }
  meet {
    log_shell "Installing npm", "curl http://npmjs.org/install.sh | #{'sudo' unless which('node').p.writable?} sh"
  }
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
