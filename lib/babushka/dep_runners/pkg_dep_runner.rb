module Babushka
  class PkgDepRunner < BaseDepRunner

    delegate :pkg_manager, :to => :definer

    private

    def applicable?
      !installs.blank?
    end

    def packages_present
      installs.all? {|pkg| pkg_manager.has? pkg }
    end

    def cmds_in_path
      present, missing = provides.partition {|cmd_name| cmd_dir(cmd_name) }
      good, bad = present.partition {|cmd_name| pkg_manager.cmd_in_path? cmd_name }

      log_ok "#{good.map {|i| "'#{i}'" }.to_list} run#{'s' if good.length == 1} from #{cmd_dir(good.first)}." unless good.empty?
      log_error "#{missing.map {|i| "'#{i}'" }.to_list} #{missing.length == 1 ? 'is' : 'are'} missing from your PATH." unless missing.empty?

      unless bad.empty?
        log_error "#{bad.map {|i| "'#{i}'" }.to_list} incorrectly run#{'s' if bad.length == 1} from #{cmd_dir(bad.first)}."
        log "You need to put #{pkg_manager.bin_path} before #{cmd_dir(bad.first)} in your PATH."
        :fail
      else
        missing.empty?
      end
    end

    def install_packages
      pkg_manager.install! installs
    end

  end
end
