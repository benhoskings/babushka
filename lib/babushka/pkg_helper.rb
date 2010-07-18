module Babushka
  class PkgHelper
  class << self
    include Shell::Helpers

    def pkg_binary; pkg_cmd end

    def all_manager_keys
      [:apt, :brew, :macports, :src]
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
      log_shell "Installing #{pkgs.to_list} via #{manager_key}", "#{pkg_cmd} install #{pkgs.join(' ')} #{opts}", :sudo => should_sudo?
    end
    def prefix
      cmd_dir(pkg_binary).p.dir
    end
    def bin_path
      prefix / 'bin'
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
      if pkg_update_timeout.nil?
        true # not required
      else
        list_age = Time.now - pkg_list_dir.mtime
        if list_age > pkg_update_timeout
          update_pkg_lists "#{manager_dep.capitalize} package lists are #{list_age.round.xsecs} old. Updating"
        else
          debug "#{manager_dep.capitalize} package lists are #{list_age.round.xsecs} old (up to date)."
          true # up to date
        end
      end
    end
    def update_pkg_lists message = "Updating #{manager_dep.capitalize} package lists"
      log_shell message, pkg_update_command, :sudo => should_sudo?
    end
    def pkg_update_timeout
      nil # not required by default
    end
    def pkg_update_command
      "#{pkg_cmd} update"
    end

    def cmdline_spec_for pkg
      "#{pkg.name}#{" --version '#{pkg.version}'" unless pkg.version.blank?}"
    end
  end
  end
end
