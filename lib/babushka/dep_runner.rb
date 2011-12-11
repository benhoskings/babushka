module Babushka
  module DepRunner
    include GitHelpers
    include UriHelpers

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

    def call_task task_name
      if (task_block = send(task_name)).nil?
        true
      else
        instance_eval(&task_block)
      end
    end

  end
end
