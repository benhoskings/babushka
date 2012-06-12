dep 'git', :version do
  requires_when_unmet {
    # Use the binary installer on OS X, so installing babushka
    # (which pulls in git) doesn't require a compiler.
    on :osx, 'git.installer'.with(version)
    # git-1.5 can't clone https:// repos properly. Let's build
    # our own rather than monkeying with unstable debs.
    on :lenny, 'git.src'.with(version)
    otherwise 'git.bin'
  }
  met? { in_path? 'git >= 1.6' }
end

dep 'git.bin' do
  installs {
    via :macports, 'git-core +svn +bash_completion'
    via :apt, 'git-core'
    via :binpkgsrc, 'scmgit'
    otherwise 'git'
  }
end

dep 'git.installer', :version do
  version.default!('1.7.10.1')
  requires 'layout.fhs'.with('/usr/local')
  source "http://git-osx-installer.googlecode.com/files/git-#{version}-intel-universal-snow-leopard.dmg"
  provides "git >= #{version}"
  after {
    sudo "ln -sf /usr/local/git/bin/git* /usr/local/bin"
  }
end

dep 'git.src', :version do
  version.default!('1.7.10.2')
  requires 'gettext.lib'
  source "http://git-core.googlecode.com/files/git-#{version}.tar.gz"
end
