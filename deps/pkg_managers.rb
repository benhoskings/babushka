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
    on :ubuntu, 'apt source'.with(:repo => 'main'), 'apt source'.with(:repo => 'universe')
    on :debian, 'apt source'.with(:repo => 'main')
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
    on :brew, 'python.bin' # homebrew installs pip along with python.
    otherwise 'pip.bin'
  }
end

dep 'pip.bin' do
  requires 'python.bin' # To ensure python-dev is pulled in.
  installs 'python-pip'
end
