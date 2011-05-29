dep 'git' do
  requires {
    # Use the binary installer on OS X, so installing babushka
    # (which pulls in git) doesn't require a compiler.
    on :osx, 'git.installer'
    otherwise 'git.managed'
  }
  met? { in_path? 'git >= 1.6' }
end

dep 'git.managed' do
  installs {
    via :macports, 'git-core +svn +bash_completion'
    via :apt, 'git-core'
    otherwise 'git'
  }
end

dep 'git.installer' do
  requires_when_unmet 'usr-local.install_path'
  source "http://git-osx-installer.googlecode.com/files/git-1.7.5.3-x86_64-leopard.dmg"
  after {
    cd '/usr/local/bin' do
      sudo "ln -sf /usr/local/git/bin/git* ."
    end
  }
end
