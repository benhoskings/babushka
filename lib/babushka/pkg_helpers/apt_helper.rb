module Babushka
  class AptHelper < PkgHelper
  class << self
    def pkg_type; :deb end
    def pkg_cmd; "env DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND='noninteractive' #{pkg_binary}" end
    def pkg_binary
      @_cached_pkg_binary ||= which('aptitude') ? 'aptitude' : 'apt-get'
    end
    def manager_key; :apt end

    def _install! pkgs, opts
      log_shell "Downloading", "#{pkg_cmd} -y -d install #{pkgs.join(' ')}", :sudo => should_sudo?
      super
    end

    def update_pkg_lists_if_required
      if !File.exists? '/var/lib/apt/lists/lock'
        update_pkg_lists "Looks like apt hasn't been used on this system yet. Updating"
      else
        super
      end
    end

    def source_for_system
      {
        :debian => 'http://archive.debian.org/debian',
        :ubuntu => 'http://archive.ubuntu.com/ubuntu'
      }[Base.host.flavour]
    end

    private
    def _has? pkg_name
      status = failable_shell("dpkg -s #{pkg_name}").stdout.val_for('Status')
      status && status.split(' ').include?('installed')
    end

    def pkg_update_timeout
      3600 * 24 # 1 day
    end
    def pkg_list_dir
      '/var/lib/apt/lists'.p
    end

  end
  end
end
