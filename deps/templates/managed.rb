managed_template = lambda{
  def packages
    installs.versions
  end

  def packages_present?
    packages.all? {|pkg| pkg_manager.has? pkg }
  end

  requires pkg_manager.manager_dep
  met? {
    if installs.blank?
      log_ok "Nothing to install on #{pkg_manager.manager_key}-based systems."
    else
      packages_present? and in_path?(provides)
    end
  }
  before {
    pkg_manager.update_pkg_lists_if_required
  }
  meet {
    pkg_manager.install! packages
  }
}

meta :managed do
  accepts_list_for :installs, :basename, :choose_with => :via
  accepts_list_for :provides, :basename, :choose_with => :via

  def pkg_manager
    Babushka.host.pkg_helper
  end

  template(&managed_template)
end

meta :gem do
  accepts_list_for :installs, :basename, :choose_with => :via
  accepts_list_for :provides, :basename, :choose_with => :via

  def pkg_manager
    Babushka::GemHelper
  end

  template(&managed_template)
end

meta :pip do
  accepts_list_for :installs, :basename, :choose_with => :via
  accepts_list_for :provides, :basename, :choose_with => :via

  def pkg_manager
    Babushka::PipHelper
  end

  template(&managed_template)
end

meta :npm do
  accepts_list_for :installs, :basename, :choose_with => :via
  accepts_list_for :provides, [], :choose_with => :via

  def pkg_manager
    Babushka::NpmHelper
  end

  template(&managed_template)
end
