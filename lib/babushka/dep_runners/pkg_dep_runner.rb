module Babushka
  class PkgDepRunner < BaseDepRunner

    private

    def applicable?
      !installs.blank?
    end

    def packages_met?
      if !applicable?
        log_ok "Not required on #{pkg_manager.manager_key}-based systems."
      else
        packages_present? and cmds_in_path?
      end
    end

    def packages_present?
      installs.all? {|pkg| pkg_manager.has? pkg }
    end

    def setup_for_install
      pkg_manager.setup_for_install_of the_dep, installs
    end

    def install_packages!
      pkg_manager.install! installs
    end

  end
end
