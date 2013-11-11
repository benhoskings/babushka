class Babushka::GitFS

  GITIGNORE_FILE = (Babushka::Path.path / 'conf/git_fs_gitignore')

  def self.snapshotting_with message, &blk
    if Babushka::Base.task.opt(:git_fs)
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
    unless repo.exists?
      repo.init!(File.read(GITIGNORE_FILE))
      commit("Add the base system.")
    end
  end

  def self.repo
    # Using :run_as_owner means babushka will sudo to commit to the gitfs when
    # meeting deps as a regular user. For this to work well, the app user
    # should have passwordless sudo during provisioning, revoked on completion.
    @repo ||= Babushka::GitRepo.new('/', :run_as_owner => true)
  end
end
