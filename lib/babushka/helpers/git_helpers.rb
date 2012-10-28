module Babushka
  module GitHelpers
    # Make these helpers directly callable, and private when included.
    module_function

    def git uri, opts = {}, &block
      repo = GitRepo.new(opts[:to] || (BuildPrefix / File.basename(uri.to_s).chomp('.git')))

      if git_update(uri, repo)
        repo.root.touch # so we can tell when it was last updated
        block.nil? || PathHelpers.cd(repo.path, &block)
      end
    end

    def git_update uri, repo
      if !repo.exists?
        update_and_log uri, repo, "Cloning #{uri} into #{repo.path}" do
          repo.clone! uri
        end
      else
        update_and_log uri, repo, "Updating #{repo.path} from #{uri}" do
          repo.repo_shell('git fetch origin')
        end
      end
    end

    def update_and_log uri, repo, message, &block
      LogHelpers.log_block message do
        if !block.call
          # failed
        elsif !repo.behind?
          LogHelpers.log " at #{repo.current_head.colorize('yellow')},", :newline => false
          true
        else
          LogHelpers.log " #{repo.current_head.colorize('yellow')}..#{repo.repo_shell("git rev-parse --short origin/#{repo.current_branch}").colorize('yellow')} (#{repo.repo_shell("git log -1 --pretty=format:%s origin/#{repo.current_branch}").chomp('.')}),", :newline => false
          repo.reset_hard! "origin/#{repo.current_branch}"
        end
      end
    end
  end
end
