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
  end
end
