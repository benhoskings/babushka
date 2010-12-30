module Babushka
  class GitRepoError < StandardError
  end
  class GitRepoExists < GitRepoError
  end
  class GitRepo
    include PathHelpers
    extend PathHelpers

    attr_reader :path

    def self.repo_for path
      maybe = shell("git rev-parse --git-dir", :dir => path) if path.p.dir?
      maybe == '.git' ? path.p : maybe / '..' unless maybe.nil?
    end

    def initialize path
      @path = path.p
    end

    def root
      @root ||= self.class.repo_for(path)
    end

    def exists?
      !root.nil? && root.exists?
    end

    def repo_shell cmd, opts = {}
      if !exists?
        raise GitRepoError, "There is no repo at #{@path}."
      else
        shell cmd, opts.merge(:dir => root)
      end
    end

    def clean?
      repo_shell("git diff-index --name-status HEAD").empty?
    end

    def dirty?
      !clean?
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

    def remote_branch_exists?
      repo_shell('git branch -a').split("\n").map(&:strip).detect {|b|
        b[/^(remotes\/)?origin\/#{current_branch}$/]
      }
    end

    def ahead?
      !remote_branch_exists? ||
      !repo_shell("git rev-list origin/#{current_branch}..").split("\n").empty?
    end

    def behind?
      remote_branch_exists? &&
      !repo_shell("git rev-list ..origin/#{current_branch}").split("\n").empty?
    end

    def clone! from
      raise GitRepoExists, "Can't clone #{from} to existing path #{path}." if exists?
      log_block "Cloning #{from}" do
        failable_shell("git clone '#{from}' '#{path.basename}'", :dir => path.parent, :create => true).tap {|shell|
          raise GitRepoError, "Couldn't clone to #{path}: #{error_message_for shell.stderr}" unless shell.result
        }.result
      end
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
