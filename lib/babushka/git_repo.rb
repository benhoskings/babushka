module Babushka
  class GitRepo
    include PathHelpers
    extend PathHelpers

    attr_reader :path

    def self.repo_for path
      in_dir(path) {
        maybe = shell("git rev-parse --git-dir")
        maybe.p / '..' unless maybe.nil?
      }
    end

    def initialize path
      @path = self.class.repo_for(path)
    end

    def clean?
      in_dir(path) { shell("git ls-files -m").empty? }
    end

    def dirty?
      !clean?
    end

    def current_branch
      File.read(path / '.git/HEAD').strip.sub(/^.*refs\/heads\//, '')
    end

    def current_head
      in_dir(path) { shell("git rev-parse --short HEAD") }
    end

    def remote_branch_exists?
      in_dir(path) {
        shell('git branch -a').split("\n").map(&:strip).detect {|b|
          b[/^(remotes\/)?origin\/#{current_branch}$/]
        }
      }
    end

    def pushed?
      in_dir(path) {
        remote_branch_exists? &&
        shell("git rev-list origin/#{current_branch}..").split("\n").empty?
      }
    end
  end
end
