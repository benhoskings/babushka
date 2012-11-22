dep 'package manager', :cmd do
  met? {
    in_path?(cmd).tap {|result|
      unmeetable! "The package manager's binary, #{cmd}, isn't in the $PATH." unless result
    }
  }
end

dep 'apt' do
  requires 'package manager'.with('apt-get')
  requires {
    on(:ubuntu, 'apt source'.with(:repo => 'main'))
    on(:ubuntu, 'apt source'.with(:repo => 'universe'))

    on(:debian, 'apt source'.with(:repo => 'main'))
  }
end

dep 'homebrew' do
  requires 'binary.homebrew', 'build tools'
end

dep 'npm' do
  requires {
    on :osx, 'npm.src'
    otherwise 'npm.bin'
  }
end

dep 'npm.src' do
  requires 'nodejs.bin'
  met? { which 'npm' }
  meet {
    log_shell "Installing npm", "curl https://npmjs.org/install.sh | #{'sudo' unless which('node').p.writable?} sh"
  }
end

dep 'npm.bin' do
  provides 'npm >= 1.1'
end

dep 'pip' do
  requires {
    on :osx, 'pip.src'
    otherwise 'pip.bin'
  }
end

dep 'pip.bin' do
  installs 'python-pip'
end

dep 'pip.src' do
  source 'http://pypi.python.org/packages/source/p/pip/pip-0.8.3.tar.gz'
  process_source {
    log_shell "Installing pip", "python setup.py install", :sudo => !which('python').p.writable?
  }
end
