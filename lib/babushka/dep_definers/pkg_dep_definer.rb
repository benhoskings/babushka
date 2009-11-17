module Babushka
  class PkgDepDefiner < BaseDepDefiner

    accepts_list_for :installs, :default_pkg, :choose_with => :via
    accepts_list_for :provides, :default_pkg, :choose_with => :via
    accepts_list_for :service_name, :name
    accepts_list_for :cfg

    def pkg_manager
      PkgHelper.for_system
    end

    def process
      requires pkg_manager.manager_dep
      internal_setup { internal_pkg_setup }
      met? { packages_met? }
      before { pkg_manager.update_pkg_lists_if_required }
      meet { install_packages! }
    end


    private

    def chooser
      PkgHelper.for_system.manager_key
    end

    def chooser_choices
      # TODO integrate into SystemSpec, like SystemSpec.all_systems
      [:apt, :brew, :macports, :src]
    end

    def default_pkg
      VersionOf.new name
    end

  end
end
