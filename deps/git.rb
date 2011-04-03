dep 'git' do
  requires {
    # Use the binary installer on OS X, so installing babushka
    # (which pulls in git) doesn't require a compiler.
    on :osx, 'git.installer'
    otherwise 'git.managed'
  }
  met? { provided? 'git >= 1.7' }
end

dep 'git.ppa' do
  adds 'ppa:git-core/ppa'
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
  source "http://git-osx-installer.googlecode.com/files/git-1.7.4.1-x86_64-leopard.dmg"
  after {
    in_dir '/usr/local/bin' do
      sudo "ln -sf /usr/local/git/bin/git* ."
    end
  }
end
