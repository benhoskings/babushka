pkg 'git' do
  installs {
    via :apt, 'git-core'
    via :brew, 'git'
    via :macports, 'git-core +svn +bash_completion'
  }
end
