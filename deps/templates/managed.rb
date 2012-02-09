managed_template = L{
  def packages
    installs.versions
  end

  def packages_present?
    packages.all? {|pkg| pkg_manager.has? pkg }
  end

  def add_cfg_deps
    cfg.all? {|target|
      target_file = target.to_s
      source_file = load_path.dirname / name / "#{File.basename(target_file)}.erb"
      requires(dep("#{File.basename(target_file)} for #{name}") {
        met? { babushka_config? target_file }
        before {
          shell "mkdir -p #{File.dirname(target_file)}", :sudo => !File.writable?(File.dirname(File.dirname(target_file)))
          shell "chmod o+rx #{File.dirname(target_file)}", :sudo => !File.writable?(File.dirname(target_file))
        }
        meet { render_erb source_file, :to => target_file, :sudo => !File.writable?(File.dirname(target_file)) }
        on :linux do
          after { service_name.each {|s| sudo "/etc/init.d/#{s} restart" } }
        end
      })
    }
  end

  requires pkg_manager.manager_dep
  prepare {
    add_cfg_deps
  }
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
  accepts_list_for :service_name, :name
  accepts_list_for :cfg

  def pkg_manager
    Babushka.host.pkg_helper
  end

  def chooser
    Babushka.host.match_list
  end

  def chooser_choices
    Babushka::PkgHelper.all_manager_keys + Babushka::SystemDefinitions.all_tokens
  end

  template(&managed_template)
end

meta :gem do
  accepts_list_for :installs, :basename, :choose_with => :via
  accepts_list_for :provides, :basename, :choose_with => :via
  accepts_list_for :service_name, :name
  accepts_list_for :cfg

  def pkg_manager
    Babushka::GemHelper
  end

  template(&managed_template)
end

meta :pip do
  accepts_list_for :installs, :basename, :choose_with => :via
  accepts_list_for :provides, :basename, :choose_with => :via
  accepts_list_for :service_name, :name
  accepts_list_for :cfg

  def pkg_manager
    Babushka::PipHelper
  end

  template(&managed_template)
end

meta :npm do
  accepts_list_for :installs, :basename, :choose_with => :via
  accepts_list_for :provides, [], :choose_with => :via
  accepts_list_for :service_name, :name
  accepts_list_for :cfg

  def pkg_manager
    Babushka::NpmHelper
  end

  template(&managed_template)
end
