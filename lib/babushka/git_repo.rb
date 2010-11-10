module Babushka
  class GitRepo
    include PathHelpers
    extend PathHelpers

    attr_reader :repo

    def self.repo_for path
      in_dir(path) {
        maybe = shell("git rev-parse --git-dir")
        maybe.p / '..' unless maybe.nil?
      }
    end

    def initialize path
      @repo = self.class.repo_for(path)
    end

    def clean?
      in_dir(repo) { shell("git ls-files -m").empty? }
    end

    def dirty?
      !clean?
    end

    def current_branch
      File.read(repo / '.git/HEAD').strip.sub(/^.*refs\/heads\//, '')
    end

    def current_head
      in_dir(repo) { shell("git rev-parse --short HEAD") }
    end

    def remote_branch_exists?
      in_dir(repo) {
        shell('git branch -a').split("\n").map(&:strip).detect {|b|
          b[/^(remotes\/)?origin\/#{current_branch}$/]
        }
      }
    end

    def pushed?
      in_dir(repo) {
        remote_branch_exists? &&
        shell("git rev-list origin/#{current_branch}..").split("\n").empty?
      }
    end

    def inspect
      "#<GitRepo:#{repo} : #{current_branch}@#{current_head}#{' (dirty)' if dirty?}>"
    end
  end
end
