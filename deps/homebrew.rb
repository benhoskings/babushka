meta :homebrew do
  def path
    Babushka::BrewHelper.present? ? Babushka::BrewHelper.prefix : '/usr/local'
  end
  def repo
    Babushka::GitRepo.new path
  end
end

dep 'binary.homebrew' do
  requires 'repo.homebrew'
  met? { which 'brew' }
  meet { log_shell "Resetting to HEAD", "git reset --hard", :cd => path }
end

dep 'repo.homebrew' do
  requires_when_unmet 'writable.fhs'.with(path), 'git'
  met? {
    if repo.exists? && !repo.include?('29d85578e75170a6c0eaebda4d701b46f1acf446')
      unmeetable "There is a non-homebrew repo at #{path}."
    else
      repo.exists?
    end
  }
  meet {
    git "https://github.com/mxcl/homebrew.git" do
      log_shell "Gitifying #{path}", "cp -r .git '#{path}'"
    end
  }
end
