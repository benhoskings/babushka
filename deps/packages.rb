pkg 'autoconf'
pkg 'build-essential' do
  provides 'gcc', 'g++', 'make', 'ld'
end
pkg 'coreutils' do
  installs { macports 'coreutils' }
  provides 'gecho'
  after {
    in_dir '/opt/local/bin' do
      sudo "ln -s gecho echo"
    end
  }
end
pkg 'curl' do
  installs {
    apt 'curl'
  }
end
dep 'doc' do
  requires 'doxygen', 'gettext'
end
pkg 'doxygen'
pkg 'freeimage' do
  installs {
    apt %w[libfreeimage3 libfreeimage-dev]
    macports 'freeimage'
  }
  provides []
end
pkg 'gettext'
pkg 'git' do
  installs {
    apt 'git-core'
    macports 'git-core +svn +bash_completion'
  }
end
gem 'image_science' do
  requires 'freeimage'
  provides []
end
pkg 'java' do
  installs { apt 'sun-java6-jre' }
  provides 'java'
  after { shell "set -Ux JAVA_HOME /usr/lib/jvm/java-6-sun" }
end
pkg 'libssl headers' do
  installs { apt 'libssl-dev' }
  provides []
end
pkg 'ncurses' do
  installs {
    apt 'libncurses5-dev', 'libncursesw5-dev'
    macports 'ncurses', 'ncursesw'
  }
  provides []
end
gem 'passenger' do
  provides 'passenger-install-nginx-module'
end
pkg 'rcconf' do
  installs { apt 'rcconf' }
end
pkg 'sed' do
  installs { macports 'gsed' }
  provides 'sed'
  after {
    in_dir '/opt/local/bin' do
      sudo "ln -s gsed sed"
    end
  }
end
pkg 'sshd' do
  installs {
    apt 'openssh-server'
  }
end
pkg 'vim'
pkg 'wget'
pkg 'zlib headers' do
  installs { apt 'zlib1g-dev' }
  provides []
end
