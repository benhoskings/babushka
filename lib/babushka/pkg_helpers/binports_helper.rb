module Babushka
  class BinPortsHelper < PkgHelper
  class << self
    def existing_packages
      shell("pkg_info").lines.to_a.map {|i| i.split(/\s+/)[0] }
    end

    # Regarding FreeBSD binary packages the following should be noted:
    #   pkg_add uses PACKAGESITE and PACKAGEROOT environment variables
    #   to calculate the URL to download packages from.
    #
    #   If you're using outdated FreeBSD RELEASE branch (like 6.2-release)
    #   that does not have anymore it's public package repository, please
    #   either consider to move to the STABLE one (like 6-release)
    #   or set PACKAGESITE var to point to appropriate package repository.

    def pkg_binary; 'pkg_add' end
    def pkg_cmd; "#{pkg_binary} -r" end
    def pkg_type; :tbz end
    def manager_key; :binports end

    private

    def _install! pkgs, opts
      log_shell "Installing #{pkgs.join(', ')}", "#{pkg_cmd} #{pkgs.join(' ')}", :sudo => should_sudo?
    end

    def _has? pkg
      existing_packages.any? {|i| i.match(/#{pkg}/)}
    end

  end
  end
end
