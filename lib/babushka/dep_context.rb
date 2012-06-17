module Babushka
  class DepContext < DepDefiner
    include GitHelpers
    include UriHelpers

    accepts_list_for :requires
    accepts_list_for :requires_when_unmet

    accepts_block_for :setup
    accepts_block_for :met?

    accepts_block_for :prepare
    accepts_block_for :before
    accepts_block_for :meet
    accepts_block_for :after

    private

    def in_path? provided_list
      PathChecker.in_path? provided_list
    end
  end
end
