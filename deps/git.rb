dep 'git' do
  requires {
    # Use the binary installer on OS X, so installing babushka
    # (which pulls in git) doesn't require a compiler.
    on :osx, 'git.installer'
    otherwise 'git.managed'
  }
  met? { in_path? 'git >= 1.5' }
end

dep 'git.managed' do
  installs {
    via :macports, 'git-core +svn +bash_completion'
    via :apt, 'git-core'
    otherwise 'git'
  }
end

dep 'git.installer', :version do
  version.default!('1.7.7')
  source "http://git-osx-installer.googlecode.com/files/git-#{version}-intel-universal-snow-leopard.dmg"
  provides "git >= #{version}"
  after {
    cd '/usr/local/bin', :create => true, :sudo => true do
      sudo "ln -sf /usr/local/git/bin/git* ."
    end
  }
end
