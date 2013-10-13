
class Babushka::GitFS

  GITIGNORE_FILE = (Babushka::Path.path / 'conf/git_fs_gitignore')

  def self.commit message
    new.commit(message)
  end

  def commit message
    init
    repo.repo_shell('git add -A .')
    repo.commit!(message)
  end

  def init
    repo.init!(File.read(GITIGNORE_FILE)) unless repo.exists?
  end

  def repo
    @repo ||= Babushka::GitRepo.new('/')
  end
end
