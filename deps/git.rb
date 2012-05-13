dep 'git' do
  requires_when_unmet {
    # Use the binary installer on OS X, so installing babushka
    # (which pulls in git) doesn't require a compiler.
    on :osx, 'git.installer'
    # git-1.5 can't clone https:// repos properly. Let's build
    # our own rather than monkeying with unstable debs.
    on :lenny, 'git.src'
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
  source "http://git-osx-installer.googlecode.com/files/git-#{version}-intel-universal-snow-leopard.dmg"
  provides "git >= #{version}"
  after {
    cd '/usr/local/bin', :create => true, :sudo => true do
      sudo "ln -sf /usr/local/git/bin/git* ."
    end
  }
end

dep 'git.src', :version do
  version.default!('1.7.9.4')
  requires 'gettext.managed'
  source "http://git-core.googlecode.com/files/git-#{version}.tar.gz"
end
