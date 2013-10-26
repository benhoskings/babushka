
class Babushka::GitFS

  GITIGNORE_FILE = (Babushka::Path.path / 'conf/git_fs_gitignore')

  def self.commit message
    repo.repo_shell('git add -A .')
    repo.commit!(message)
  end

  def self.init
    repo.init!(File.read(GITIGNORE_FILE)) unless repo.exists?
  end

  def self.repo
    @repo ||= Babushka::GitRepo.new('/')
  end
end
