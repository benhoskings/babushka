module Babushka
  class GitRepoError < StandardError
  end
  class GitRepoExists < GitRepoError
  end
  # This class is used for manipulating git repositories (see {#initialize} how to start). Mostly it provides shortcuts to most often used git commands.
  # @example Example of usage:
  #   @repo ||= Babushka::GitRepo.new('.')
  #   @repo.clone "https://github.com/benhoskings/babushka"
  #   @repo.checkout! "devel"
  #
  # For practical example how to use GitRepo class, see Ben Hoskings {https://github.com/benhoskings/babushka-deps/blob/master/push.rb push dep}
  #
  # Methods for checking repositrory state:
  #
  # * {#clean?}
  # * {#dirty?}
  # * {#include?} ref
  # * {#ahead?}
  # * {#behind?}
  # * {#rebasing?}
  # * {#applying?}
  # * {#merging?}
  # * {#bisecting?}
  # * {#rebase_merging?}
  # * {#rebasing_interactively?}
  #
  # Methods for repository operations:
  # 
  # * {#clone!}
  # * {#branch!}
  # * {#track!}
  # * {#checkout!}
  # * {#reset_hard!} refspec
  
  class GitRepo
    include ShellHelpers
    extend ShellHelpers

    def self.repo_for path
      maybe = shell("git rev-parse --git-dir", :cd => path) if path.p.dir?
      maybe == '.git' ? path.p : maybe / '..' unless maybe.nil?
    end
    # @example Initialize repo in current dir
    #   @repo ||= Babushka::GitRepo.new('.')
    def initialize path
      @raw_path = path
    end

    def path
      @path ||= @raw_path.p
    end

    def root
      @root ||= self.class.repo_for(path)
    end

    def git_dir
      root / '.git'
    end

    def exists?
      !root.nil? && root.exists?
    end
    # executes shell command setting current directory to repository root
    #
    def repo_shell cmd, opts = {}, &block
      if !exists?
        raise GitRepoError, "There is no repo at #{@path}."
      else
        shell cmd, opts.merge(:cd => root), &block
      end
    end

    def clean?
      repo_shell("git status") # Sometimes git caches invalid index info; this clears it.
      repo_shell("git diff-index --name-status HEAD", &:stdout).blank?
    end

    def dirty?
      !clean?
    end

    def include? ref
      repo_shell("git rev-list -n 1 '#{ref}'")
    end

    def ahead?
      !remote_branch_exists? ||
      !repo_shell("git rev-list origin/#{current_branch}..").split("\n").empty?
    end

    def behind?
      remote_branch_exists? &&
      !repo_shell("git rev-list ..origin/#{current_branch}").split("\n").empty?
    end

    def rebasing?
      %w[rebase rebase-apply ../.dotest].any? {|d|
        (git_dir / d).exists?
      } or rebase_merging? or rebasing_interactively?
    end

    def applying?
      %w[rebase rebase-apply ../.dotest].any? {|d|
        (git_dir / d / 'applying').exists?
      }
    end

    def merging?
      (git_dir / 'MERGE_HEAD').exists? or rebase_merging?
    end

    def bisecting?
      (git_dir / 'BISECT_LOG').exists?
    end

    def rebase_merging?
      %w[rebase-merge .dotest-merge].any? {|d|
        (git_dir / d).exists?
      }
    end

    def rebasing_interactively?
      %w[rebase-merge .dotest-merge].any? {|d|
        (git_dir / d / 'interactive').exists?
      }
    end

    def branches
      repo_shell('git branch').split("\n").map {|l| l.sub(/^[* ]+/, '') }
    end

    def current_branch
      repo_shell("cat .git/HEAD").strip.sub(/^.*refs\/heads\//, '')
    end

    def current_head
      repo_shell("git rev-parse --short HEAD")
    end

    def current_full_head
      repo_shell("git rev-parse HEAD")
    end

    def remote_branch_exists?
      repo_shell('git branch -a').split("\n").map(&:strip).detect {|b|
        b[/^(remotes\/)?origin\/#{current_branch}$/]
      }
    end

    def clone! from
      raise GitRepoExists, "Can't clone #{from} to existing path #{path}." if exists?
      shell("git clone '#{from}' '#{path.basename}'", :cd => path.parent, :create => true) {|shell|
        shell.ok? || raise(GitRepoError, "Couldn't clone to #{path}: #{error_message_for shell.stderr}")
      }
    end

    def branch! branch
      repo_shell("git branch '#{branch}'")
    end

    def track! branch
      repo_shell("git checkout -t '#{branch}'")
    end

    def checkout! branch
      repo_shell("git checkout '#{branch}'")
    end

    def reset_hard! refspec = 'HEAD'
      repo_shell("git reset --hard #{refspec}")
    end

    def inspect
      "#<GitRepo:#{root} : #{current_branch}@#{current_head}#{' (dirty)' if dirty?}>"
    end

    private

    def error_message_for git_error
      git_error.sub(/^fatal\: /, '').sub(/\n.*$/m, '').end_with('.')
    end
  end
end
