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
        packages_present? and provided?
      end
    end

    def packages_present?
      installs.all? {|pkg| pkg_manager.has? pkg }
    end

    def internal_pkg_setup
      add_cfg_deps and setup_for_install
    end

    def add_cfg_deps
      cfg.all? {|target|
        target_file = target.to_s
        source_file = File.dirname(source_path) / name / "#{File.basename(target_file)}.erb"
        requires(dep("#{target_file} for #{name}") {
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

    def setup_for_install
      pkg_manager.setup_for_install_of the_dep, installs
    end

    def install_packages!
      pkg_manager.install! installs
    end

  end
end
