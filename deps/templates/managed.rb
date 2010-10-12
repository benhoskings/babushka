managed_template = L{
  helper :packages_present? do
    installs.all? {|pkg| pkg_manager.has? pkg }
  end

  helper :add_cfg_deps do
    cfg.all? {|target|
      target_file = target.to_s
      source_file = File.dirname(load_path) / name / "#{File.basename(target_file)}.erb"
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
  internal_setup {
    add_cfg_deps
  }
  met? {
    if installs.blank?
      log_ok "Not required on #{pkg_manager.manager_key}-based systems."
    else
      packages_present? and provided?
    end
  }
  before {
    pkg_manager.update_pkg_lists_if_required
  }
  meet {
    pkg_manager.install! installs
  }
}

meta :managed do
  accepts_list_for :installs, :default_pkg, :choose_with => :via
  accepts_list_for :provides, :default_pkg, :choose_with => :via
  accepts_list_for :service_name, :name
  accepts_list_for :cfg

  def default_pkg
    Babushka::VersionOf.new basename
  end

  def pkg_manager
    Babushka::Base.host.pkg_helper
  end

  def chooser
    [Babushka::Base.host.pkg_helper.manager_key] + Babushka::Base.host.match_list
  end

  def chooser_choices
    Babushka::PkgHelper.all_manager_keys + Babushka::Base.host.all_tokens
  end

  template &managed_template
end

meta :gem do
  accepts_list_for :installs, :default_pkg, :choose_with => :via
  accepts_list_for :provides, :default_pkg, :choose_with => :via
  accepts_list_for :service_name, :name
  accepts_list_for :cfg

  def default_pkg
    Babushka::VersionOf.new basename
  end

  def pkg_manager
    Babushka::GemHelper
  end

  template &managed_template
end
