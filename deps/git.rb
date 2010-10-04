dep 'git' do
  requires {
    on :osx, 'git.installer'
    on :linux, 'git.managed'
  }
end

dep 'git.managed' do
  installs {
    via :apt, 'git-core'
    via :yum, 'git'
    via :brew, 'git'
    via :macports, 'git-core +svn +bash_completion'
  }
  provides 'git'
end

dep 'git.installer' do
  merge :versions, 'git' => '1.7.3.1'
  requires_when_unmet 'usr-local.install_path'
  source "http://git-osx-installer.googlecode.com/files/git-#{var(:versions)['git']}-intel-leopard.dmg"
  provides 'git'
  after {
    in_dir '/usr/local/bin' do
      sudo "ln -sf /usr/local/git/bin/git* ."
    end
  }
end
