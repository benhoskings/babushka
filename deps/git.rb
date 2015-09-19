dep 'git', :version do
  # Accept a rather old git by default, so the installation process
  # doesn't unnecessarily upgrade it.
  version.default!('1.6')

  requires_when_unmet {
    # Use the binary installer on OS X, so installing babushka
    # (which pulls in git) doesn't require a compiler.
    on :osx, 'git.installer'.with(owner.version)
    # git-1.5 can't clone https:// repos properly. Let's build
    # our own rather than monkeying with unstable debs.
    on :lenny, 'git.src'.with(owner.version)
    otherwise 'git.bin'.with(owner.version)
  }
  met? { in_path? "git >= #{version}" }
end

dep 'git.bin', :version do
  # Accept any packaged git that's new enough to have proper https:// support.
  version.default!('1.6')
  installs {
    via :apt, 'git-core'
    via :binpkgsrc, 'scmgit'
    otherwise 'git'
  }
  provides "git >= #{version}"
end

dep 'git.installer', :version do
  version.default!('1.8.0')
  requires 'layout.fhs'.with('/usr/local')
  source "https://sourceforge.net/projects/git-osx-installer/files/git-#{version}-intel-universal-mavericks.dmg/download?use_mirror=autoselect"
  provides "git >= #{version}"
  after {
    sudo "ln -sf /usr/local/git/bin/git* /usr/local/bin"
  }
end

dep 'git.src', :version do
  version.default!('1.8.0')
  requires 'gettext.lib'
  source "https://github.com/git/git/archive/v#{version}.zip"
  provides "git >= #{version}"
end
