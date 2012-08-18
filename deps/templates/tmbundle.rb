meta :tmbundle, :for => :osx do
  accepts_value_for :source

  def path
    '~/Library/Application Support/TextMate/Bundles' / name
  end

  def repo
    @repo ||= Babushka::GitRepo.new(path).tap {|r|
      r.repo_shell("git fetch") if r.exists?
    }
  end

  template {
    requires 'benhoskings:TextMate.app'
    met? { repo.exists? && !repo.behind? }
    before { shell "mkdir -p '#{path.parent}'" }
    meet {
      if repo.exists?
        log_block "Updating to #{repo.current_remote_branch} (#{repo.resolve(repo.current_remote_branch)})" do
          repo.reset_hard!(repo.current_remote_branch)
        end
      else
        git source, :to => path
      end
    }
    after { log_shell "Telling TextMate to reload bundles", %Q{osascript -e 'tell app "TextMate" to reload bundles'} }
  }
end
