dep 'build tools' do
  requires {
    on :osx, 'xcode tools'
    on :linux, 'linux build tools'
  }
end

dep 'linux build tools', :template => 'bin' do
  installs {
    via :yum, %w[gcc gcc-c++ autoconf automake libtool]
    via :apt, %w[build-essential autoconf automake libtool]
    via :pacman, 'base-devel'
  }
  provides %w[gcc g++ make ld autoconf automake libtool]
end

dep 'xcode tools' do
  met? {
    in_path?(%w[cc gcc c++ g++]) && in_path?(%w[clang make ld libtool])
  }
  meet {
    unmeetable! "Install Xcode via the App Store, then go Preferences -> Downloads -> Components -> Command Line Tools."
  }
end
