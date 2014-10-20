module Babushka
  class PkgHelper
  class << self
    include LogHelpers
    include ShellHelpers

    def pkg_binary; pkg_cmd end

    def manager_dep
      'package manager'.with(pkg_binary)
    end

    def all_manager_keys
      [:apt, :pacman, :brew, :macports, :zypper, :yum, :binpkgsrc, :binports]
    end

    def present?
      which pkg_binary
    end

    def has? pkg, opts = {}
      pkg = Babushka.VersionOf(pkg)
      has_pkg?(pkg).tap {|matching_version|
        matching_pkg = Babushka.VersionOf(pkg.name, (matching_version if matching_version.is_a?(VersionStr)))
        unless opts[:log] == false
          log "system #{matching_version ? "has" : "doesn't have"} #{matching_pkg} #{pkg_type}", :as => (:ok if matching_version)
        end
      }
    end

    def install! pkgs, opts = nil
      install_pkgs! [*pkgs].map {|pkg| Babushka.VersionOf(pkg) }, opts
    end

    def handle_install! pkgs, opts = nil
      if [*pkgs].empty?
        log "Nothing to install on #{manager_key}-based systems."
      else
        update_pkg_lists_if_required
        install! pkgs, opts
      end
    end

    def prefix
      cmd_dir(pkg_binary).p.dir
    end

    def bin_path
      prefix / 'bin'
    end

    def cmd_in_path? cmd_name
      if (_cmd_dir = cmd_dir(cmd_name)).nil?
        log_error "The '#{cmd_name}' command is not available. You probably need to add #{bin_path} to your PATH."
      else
        _cmd_dir.starts_with?(prefix)
      end
    end

    def should_sudo?
      !File.writable_real?(bin_path)
    end

    def update_pkg_lists_if_required
      if pkg_update_timeout.nil?
        true # not required
      else
        list_age = Time.now - pkg_list_dir.mtime
        if list_age > pkg_update_timeout
          update_pkg_lists "The #{manager_key} package lists are #{list_age.round.xsecs} old. Updating"
        else
          debug "The #{manager_key} package lists are #{list_age.round.xsecs} old (up to date)."
          true # up to date
        end
      end
    end

    def update_pkg_lists message = "Updating #{manager_key} package lists"
      log_shell message, pkg_update_command, :sudo => should_sudo?
    end

    private

    def has_pkg? pkg_name
      raise RuntimeError, "#{self.class.name}#has_pkg? is unimplemeneted."
    end

    def install_pkgs! pkgs, opts
      log_shell "Installing #{pkgs.to_list} via #{manager_key}", "#{pkg_cmd} -y install #{pkgs.join(' ')} #{opts}", :sudo => should_sudo?
    end

    def pkg_update_timeout
      nil # not required by default
    end

    def pkg_update_command
      "#{pkg_cmd} update"
    end

    def cmdline_spec_for pkg
      "#{pkg.name}#{" --version '#{pkg.version}'" unless pkg.version.nil?}"
    end

  end
  end
end
