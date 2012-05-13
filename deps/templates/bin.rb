meta :bin do
  accepts_list_for :installs, :basename, :choose_with => :via
  accepts_list_for :provides, :basename, :choose_with => :via

  template {
    requires_when_unmet Babushka.host.pkg_helper.manager_dep

    met? {
      in_path? provides
    }

    meet {
      Babushka.host.pkg_helper.handle_install! installs
    }
  }
end
