module Babushka
  class AptHelper < PkgHelper
  class << self
    def pkg_type; :deb end
    def pkg_cmd; "env DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND='noninteractive' #{pkg_binary} -y" end
    def pkg_binary
      @_cached_pkg_binary ||= which('aptitude') ? 'aptitude' : 'apt-get'
    end
    def manager_key; :apt end

    def _install! pkgs, opts
      package_count = shell("#{pkg_cmd} -s install #{pkgs.join(' ')}", :sudo => should_sudo?).split.grep(/^Inst\b/).length
      dep_count = package_count - pkgs.length

      log "Installing #{pkgs.join(', ')} and #{dep_count} dep#{'s' unless dep_count == 1} via #{manager_key}"
      log_shell "Downloading", "#{pkg_cmd} -d install #{pkgs.join(' ')}", :sudo => should_sudo?
      log_shell "Installing", "#{pkg_cmd} install #{pkgs.join(' ')} #{opts}", :sudo => should_sudo?
    end

    def update_pkg_lists_if_required
      if !File.exists? '/var/lib/apt/lists/lock'
        log_shell "Looks like apt hasn't been used on this system yet. Updating", "apt-get update", :sudo => should_sudo?
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
      failable_shell("dpkg -s #{pkg_name}").stdout.val_for('Status').split(' ').include?('installed')
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
