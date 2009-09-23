module Babushka
  class PkgDepDefiner < BaseDepDefiner

    accepts_list_for :installs, :default_pkg
    accepts_list_for :provides, :default_pkg

    def pkg_manager
      PkgHelper.for_system
    end

    def process
      super

      requires pkg_manager.manager_dep
      internal_setup { setup_for_install }
      met? {
        if !applicable?
          log_ok "Not required on #{pkg_manager.manager_key}-based systems."
        else
          packages_present? and cmds_in_path?
        end
      }
      before { pkg_manager.update_pkg_lists_if_required }
      meet { install_packages! }
    end


    private

    def chooser
      PkgHelper.for_system.manager_key
    end

    def default_pkg
      VersionOf.new name
    end

  end
end
