meta :lib do
  accepts_list_for :installs, :basename, :choose_with => :via

  template {
    requires Babushka.host.pkg_helper.manager_dep

    met? {
      installs.all? {|pkg|
        Babushka.host.pkg_helper.has?(pkg)
      }
    }

    meet {
      Babushka.host.pkg_helper.handle_install! installs
    }
  }
end
