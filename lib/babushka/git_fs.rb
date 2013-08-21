
class Babushka::GitFS

  GITIGNORE_FILE = (Babushka::Path.path / 'conf/git_fs_gitignore')

  def commit message
    repo.init!(File.read(GITIGNORE_FILE)) unless repo.exists?
    repo.repo_shell('git add -A .')
    repo.commit!(message)
  end

  def repo
    @repo ||= Babushka::GitRepo.new('/')
  end
end
