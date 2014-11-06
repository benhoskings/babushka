module Babushka
  class ZypperHelper < PkgHelper
  class << self
    def pkg_type; :rpm end
    def pkg_cmd; pkg_binary end
    def pkg_binary; "zypper" end
    def manager_key; :zypper end

    private

    def has_pkg? pkg_name
      shell?("#{pkg_cmd} search #{pkg_name}")
    end

    def install_pkgs! pkgs, opts
      log_shell "Installing #{pkgs.to_list} via #{manager_key}", "#{pkg_cmd} -n install #{pkgs.join(' ')} #{opts}", :sudo => should_sudo?
    end

  end
  end
end
