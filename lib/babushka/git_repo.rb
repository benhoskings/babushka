module Babushka
  class GitRepoError < StandardError
  end
  class GitRepo
    include PathHelpers
    extend PathHelpers

    attr_reader :repo

    def self.repo_for path
      maybe = shell("git rev-parse --git-dir", :dir => path) if path.p.dir?
      maybe == '.git' ? path : maybe.p / '..' unless maybe.nil?
    end

    def initialize path
      @path = path
      @repo = self.class.repo_for(path)
    end

    def repo_shell cmd
      if repo.nil? || !repo.exists?
        raise GitRepoError, "There is no repo at #{@path}."
      else
        shell cmd, :dir => repo
      end
    end

    def clean?
      repo_shell("git ls-files -m").empty?
    end

    def dirty?
      !clean?
    end

    def current_branch
      repo_shell("cat .git/HEAD").strip.sub(/^.*refs\/heads\//, '')
    end

    def current_head
      repo_shell("git rev-parse --short HEAD")
    end

    def remote_branch_exists?
      repo_shell('git branch -a').split("\n").map(&:strip).detect {|b|
        b[/^(remotes\/)?origin\/#{current_branch}$/]
      }
    end

    def ahead?
      !remote_branch_exists? ||
      !repo_shell("git rev-list origin/#{current_branch}..").split("\n").empty?
    end

    def inspect
      "#<GitRepo:#{repo} : #{current_branch}@#{current_head}#{' (dirty)' if dirty?}>"
    end
  end
end
