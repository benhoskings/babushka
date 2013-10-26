
class Babushka::GitFS

  GITIGNORE_FILE = (Babushka::Path.path / 'conf/git_fs_gitignore')

  def self.snapshotting_with message, &blk
    if Base.task.opt(:git_fs)
      init
      blk.call.tap {|result| commit(message) if result }
    else
      blk.call
    end
  end

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
