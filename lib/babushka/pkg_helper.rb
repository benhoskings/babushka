module Babushka
  class PkgHelper
  class << self
    include Shell::Helpers

    def pkg_binary; pkg_cmd end

    def for_system
      {
        :osx => BrewHelper,
        :linux => AptHelper
      }[host.system]
    end

    def manager_dep
      manager_key.to_s
    end

    def has? pkg, opts = {}
      pkg = ver(pkg)
      returning _has?(pkg) do |matching_version|
        matching_pkg = ver(pkg.name, (matching_version if matching_version.is_a?(VersionStr)))
        unless opts[:log] == false
          log "system #{matching_version ? "has" : "doesn't have"} #{matching_pkg} #{pkg_type}", :as => (:ok if matching_version)
        end
      end
    end
    def install! pkgs, opts = nil
      _install! [*pkgs].map {|pkg| ver pkg }, opts
    end
    def _install! pkgs, opts
      log_shell "Installing #{pkgs.join(', ')} via #{manager_key}", "#{pkg_cmd} install #{pkgs.join(' ')} #{opts}", :sudo => should_sudo?
    end
    def setup_for_install_of dep, pkgs
      true
    end
    def prefix
      bin_path.dir
    end
    def bin_path
      cmd_dir(pkg_binary).p
    end
    def present?
      which pkg_binary
    end
    def cmd_in_path? cmd_name
      if (_cmd_dir = cmd_dir(cmd_name)).nil?
        log_error "The '#{cmd_name}' command is not available. You probably need to add #{bin_path} to your PATH."
      else
        _cmd_dir.starts_with?(prefix)
      end
    end
    def should_sudo?
      !File.writable?(bin_path)
    end
    def update_pkg_lists_if_required
      true # not required by default
    end
    def cmdline_spec_for pkg
      "#{pkg.name}#{" --version '#{pkg.version}'" unless pkg.version.blank?}"
    end
  end
  end
end
