module Babushka
  module GitHelpers
    def git uri, opts = {}, &block
      repo = GitRepo.new(opts[:to] || (BuildPrefix / File.basename(uri.to_s).chomp('.git')))
      update_success = if repo.exists?
        git_update uri, repo
      else
        repo.clone! uri
      end

      if update_success
        repo.root.touch # so we can tell when it was last updated
        block.nil? || cd(repo.path, &block)
      end
    end

    private

    def git_update uri, repo
      log_block "Updating #{uri}" do
        if repo.repo_shell('git fetch origin').nil?
          log_error " Couldn't fetch,", :newline => false
        elsif !repo.behind?
          log " Already up-to-date at #{repo.current_head.colorize('yellow')},", :newline => false
          true
        else
          log " #{repo.current_head.colorize('yellow')}..#{repo.repo_shell("git rev-parse --short origin/#{repo.current_branch}").colorize('yellow')} (#{repo.repo_shell("git log -1 --pretty=format:%s origin/#{repo.current_branch}").chomp('.')}),", :newline => false
          repo.reset_hard! "origin/#{repo.current_branch}"
        end
      end
    end
  end
end
