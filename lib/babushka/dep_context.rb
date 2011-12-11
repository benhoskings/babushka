module Babushka
  class DepContext < DepDefiner
    include GitHelpers
    include UriHelpers

    accepts_list_for :desc
    accepts_list_for :requires
    accepts_list_for :requires_when_unmet
    accepts_value_for :run_in

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

    def apps_in_path? cmds
      log_warn "#{caller.first}: #apps_in_path? shouldn't be called directly. It will be removed on 2012-02-01. Instead, use #in_path?." # deprecated
      in_path? cmds
    end

    def cmds_in_path? apps
      log_warn "#{caller.first}: #cmds_in_path? shouldn't be called directly. It will be removed on 2012-02-01. Instead, use #in_path?." # deprecated
      in_path? apps
    end
  end
end
