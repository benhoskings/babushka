module Babushka
  class GitRepoError < StandardError
  end
  class GitRepoExists < GitRepoError
  end

  # Provides some wrapper methods for interacting concisely with a git
  # repository.
  #
  # The repo is accessed by shelling out to `git` via the {repo_shell}
  # method, which makes sure the repo exists and that the commands are run
  # in the right place. Hence, GitRepo doesn't depend on your current
  # working directory.
  #
  # Most of the methods return a boolean and are used to discover things
  # about the repository, like whether it's {clean?} or {dirty?}, currently
  # {merging?} or {rebasing?}, and whether it's {ahead?} or {behind?} the
  # default remote.
  #
  # Some return a piece of data, like {current_head} and {current_branch}.
  #
  # There are also some methods that make simple changes to the repository,
  # like {checkout!} and {reset_hard!}.
  #
  # To perform other operations on the repository like committing or
  # rebasing, check out grit. This class is just a little `git` wrapper.
  #
  class GitRepo
    include ShellHelpers
    extend ShellHelpers

    attr_reader :path

    # The full path to the root of the repo {path} is within, if it is within
    # one somewhere; otherwise nil.
    def self.repo_for path
      maybe = shell?("git rev-parse --git-dir", :cd => path) if path.p.dir?

      if maybe == '.git'
        path.p
      elsif !maybe.nil?
        maybe / '..'
      end
    end

    def initialize path
      @path = path.p
    end

    # This repo's top-level directory.
    def root
      @root ||= self.class.repo_for(path)
    end

    # This repo's +.git+ directory, where git stores its objects and other repo data.
    def git_dir
      root / '.git'
    end

    # True if +root+ points to an existing git repo.
    #
    # The repo doesn't always have to exist. For example, you can pass a
    # nonexistent path when you initialize a GitRepo, and then call {clone!}
    # on it.
    def exists?
      !root.nil? && root.exists?
    end

    # Run +cmd+ on the shell, changing to this repo's {root}. If the repo
    # doesn't exist, a GitRepoError is raised.
    #
    # A GitRepo with a nonexistent {root} is valid - it will only fail if
    # an operation that requires an existing repo is attempted.
    def repo_shell cmd, opts = {}, &block
      if !exists?
        raise GitRepoError, "There is no repo at #{@path}."
      else
        shell cmd, opts.merge(:cd => root), &block
      end
    end

    def repo_shell? cmd, opts = {}
      if !exists?
        raise GitRepoError, "There is no repo at #{@path}."
      else
        shell? cmd, opts.merge(:cd => root)
      end
    end


    # True if the repo is clean, i.e. when the content in its index and working
    # copy match the commit that HEAD refers to.
    def clean?
      repo_shell("git status") # Sometimes git caches invalid index info; this clears it.
      repo_shell("git diff-index --name-status HEAD", &:stdout).blank?
    end

    # The inverse of {clean?} -- true if the content in the repo's index or
    # working copy differs from the commit HEAD refers to.
    def dirty?
      !clean?
    end

    # True if the commit referenced by +ref+ is present somewhere in this repo.
    #
    # Note that the ref being present doesn't mean that it's a parent of +HEAD+,
    # just that it currently resolves to a commit.
    def include? ref
      repo_shell("git rev-list -n 1 '#{ref}'")
    end

    # True if there are any commits in the current branch's history that
    # aren't also present on the corresponding remote branch, or if the
    # remote doesn't exist.
    def ahead?
      !remote_branch_exists? ||
      !repo_shell("git rev-list #{current_remote_branch}..").split("\n").empty?
    end

    # True if there are any commits in the current branch's corresponding remote
    # branch that aren't also present locally, if the remote branch exists.
    def behind?
      remote_branch_exists? &&
      !repo_shell("git rev-list ..#{current_remote_branch}").split("\n").empty?
    end

    # True if the repo is partway through a rebase of some kind. This could be
    # because one of the commits conflicted when it was replayed, or that the
    # rebase is interactive and is awaiting another command.
    def rebasing?
      %w[rebase rebase-apply ../.dotest].any? {|d|
        (git_dir / d).exists?
      } or rebase_merging? or rebasing_interactively?
    end

    # True if a patch is partway through being applied -- perhaps because applying
    # it caused conflicts that are yet to be resolved.
    def applying?
      %w[rebase rebase-apply ../.dotest].any? {|d|
        (git_dir / d / 'applying').exists?
      }
    end

    # True if a merge is in progress -- perhaps because it produced conflicts that
    # are yet to be resolved.
    def merging?
      (git_dir / 'MERGE_HEAD').exists? or rebase_merging?
    end

    # True if a bisect is currently in progress.
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



    # An array of the names of all the local branches in this repo.
    def branches
      names = repo_shell('git branch').split("\n").map {|l| l.sub(/^[* ]+/, '') }
      reject_non_branches(names)
    end

    def all_branches
      names = repo_shell('git branch -a').split("\n").map {|l| l.sub(/^[* ]+/, '') }
      reject_non_branches(names).reject {|i|
        i['/origin/HEAD ->']
      }.map {|i|
        i.sub(/^remotes\//, '')
      }
    end

    # The name of the branch that's currently checked out, if any. If there
    # is no current branch (i.e. if the HEAD is detached), the HEAD's SHA is
    # returned instead.
    def current_branch
      repo_shell("cat .git/HEAD").strip.sub(%r{^.*refs/heads/}, '')
    end

    # The namespaced name of the remote branch that the current local branch
    # is tracking, or on origin if the branch isn't tracking an explicit
    # remote branch.
    def current_remote_branch
      branch = current_branch
      "#{remote_for(branch)}/#{branch}"
    end

    # The short SHA of the repo's current HEAD. This is usually 7 characters,
    # but is longer when extra characters are required to disambiguate it.
    def current_head
      repo_shell("git rev-parse --short HEAD")
    end

    # The full 40 character SHA of the current HEAD.
    def current_full_head
      repo_shell("git rev-parse HEAD")
    end

    # The short SHA of the commit that +ref+ currently refers to.
    #
    # Note that it's possible for git's short SHA to change when new commits
    # enter the repo (via commit or fetch), as git adds characters to keep
    # short SHAs unique.
    def resolve ref
      repo_shell?("git rev-parse --short #{ref}")
    end

    # The full SHA of the commit that +ref+ currently refers to.
    def resolve_full ref
      repo_shell?("git rev-parse #{ref}")
    end

    # The remote assigned to branch in the git config, or 'origin' if none
    # is set. This is the remote that git pushes to and fetches from for this
    # branch by default, and the branch that comparisons like #ahead? and
    # #behind? are made against.
    def remote_for branch
      repo_shell?("git config branch.#{branch}.remote") || 'origin'
    end

    # True if origin contains a branch of the same name as the current local
    # branch.
    def remote_branch_exists?
      repo_shell?("git rev-parse refs/remotes/#{current_remote_branch}")
    end

    # Clone the remote at +from+ to this GitRepo's path. The path must be
    # nonexistent; an error is raised if the local repo already exists.
    def clone! from
      raise GitRepoExists, "Can't clone #{from} to existing path #{path}." if exists?
      shell("git clone '#{from}' '#{path.basename}'", :cd => path.parent, :create => true) {|shell|
        shell.ok? || raise(GitRepoError, "Couldn't clone to #{path}: #{error_message_for shell.stderr}")
      }
    end

    # Create a new local branch called +branch+ with +ref+ (defaulting to
    # HEAD) as its tip.
    def branch! branch, ref = 'HEAD'
      repo_shell("git branch '#{branch}' '#{ref}'")
    end

    # Create a new local tracking branch for +branch+, which should be specified
    # as remote/branch. For example, if "origin/next" is passed, a local 'next'
    # branch will be created to track origin's 'next' branch.
    def track! branch
      repo_shell("git checkout -t '#{branch}' -b '#{branch.sub(%r{^.*/}, '')}'")
    end

    # Check out the supplied ref, detaching the HEAD if the named ref
    # isn't a branch.
    def checkout! ref
      repo_shell("git checkout '#{ref}'")
    end

    # Check out the supplied ref, detaching the HEAD. If the ref is a branch
    # or tag, HEAD will reference the commit at the tip of the ref.
    def detach! ref = 'HEAD'
      repo_shell("git checkout '#{resolve(ref)}'")
    end

    # Reset the repo to the given ref, discarding changes in the index and
    # working copy.
    def reset_hard! ref = 'HEAD'
      repo_shell("git reset --hard '#{ref}'")
    end

    def inspect
      "#<GitRepo:#{root} : #{current_branch}@#{current_head}#{' (dirty)' if dirty?}>"
    end

    private

    def error_message_for git_error
      git_error.sub(/^fatal\: /, '').sub(/\n.*$/m, '').end_with('.')
    end

    def reject_non_branches branch_names
      branch_names.reject {|n|
        n['(no branch)'] || n[/^\(detached from \w+\)$/]
      }
    end
  end
end
