module Babushka
  module GitHelpers
    def git uri, opts = {}, &block
      repo = GitRepo.new(opts[:to] || (BuildPrefix / File.basename(uri.to_s)))
      update_success = if repo.exists?
        git_update uri, repo
      else
        repo.clone! uri
      end

      if update_success
        repo.root.touch # so we can tell when it was last updated
        block.nil? || in_dir(repo) {|path| block.call path }
      end
    end

    private

    def git_update uri, repo
      log_block "Updating #{uri}" do
        if repo.repo_shell('git fetch origin').nil?
          log_error "Couldn't fetch #{uri}."
        elsif !repo.behind?
          true
        else
          repo.reset_hard! "origin/#{repo.current_branch}"
        end
      end
    end
  end
end
