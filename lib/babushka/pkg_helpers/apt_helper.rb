module Babushka
  class AptHelper < PkgHelper
  class << self
    def pkg_type; :deb end
    def pkg_cmd; "env DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND='noninteractive' #{pkg_binary}" end
    def manager_key; :apt end

    def pkg_binary
      @_cached_pkg_binary ||= which('aptitude') ? 'aptitude' : 'apt-get'
    end

    def manager_dep
      'apt'
    end

    def update_pkg_lists_if_required
      wait_for_dpkg
      if !File.exists? '/var/lib/apt/lists/lock'
        update_pkg_lists "Looks like apt hasn't been used on this system yet. Updating"
      else
        super
      end
    end

    def source_for_system
      {
        :debian => 'http://http.debian.net/debian',
        :ubuntu => 'http://archive.ubuntu.com/ubuntu'
      }[Babushka.host.flavour]
    end

    def source_matcher_for_system
      {
        :debian => %r{http://(ftp\d?\.(\w\w\.)?debian\.org|(http|cdn)\.debian\.net)/debian/?},
        :ubuntu => %r{http://((\w\w-(.*)-\d\.ec2\.)|(\w\w\.))?archive\.ubuntu\.com/ubuntu/?}
      }[Babushka.host.flavour]
    end


    private

    def has_pkg? pkg
      pkg_name = pkg.name.sub(/\=.*$/, '') # Strip versions like git=1.7.11
      wait_for_dpkg
      status = raw_shell("dpkg -s #{pkg_name}").stdout.val_for('Status')
      status && status.split(' ').include?('installed')
    end

    def install_pkgs! pkgs, opts
      wait_for_dpkg
      super
    end

    def pkg_update_timeout
      3600 * 24 # 1 day
    end

    def pkg_list_dir
      '/var/lib/apt/lists'.p
    end

    def wait_for_dpkg
      if dpkg_locked?
        log_block "Looks like dpkg is already in use - waiting" do
          sleep 1 while dpkg_locked?
          true
        end
      end
    end

    def dpkg_locked?
      which('fuser') and raw_shell('fuser -v /var/lib/dpkg/lock').stderr[/\bF..../]
    end
  end
  end
end
