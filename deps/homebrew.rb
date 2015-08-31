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
  met? { in_path? 'brew' }
  meet { log_shell "Resetting to HEAD", "git reset --hard", :cd => path }
end

dep 'repo.homebrew' do
  requires_when_unmet 'writable.fhs'.with(path), 'git'
  met? {
    repo.exists?
  }
  meet {
    git "https://github.com/mxcl/homebrew.git" do
      log_shell "Gitifying #{path}", "cp -r .git '#{path}'"
    end
  }
end
