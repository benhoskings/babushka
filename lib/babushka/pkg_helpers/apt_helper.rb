module Babushka
  class AptHelper < PkgHelper
  class << self
    def pkg_type; :deb end
    def pkg_cmd; "DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND='noninteractive' apt-get -qyu" end
    def pkg_binary; "apt-get" end
    def manager_key; :apt end

    def install! pkgs
      package_count = sudo("#{pkg_cmd} -s install #{pkgs.join(' ')}").split.grep(/^Inst\b/).length
      dep_count = package_count - pkgs.length

      log "Installing #{pkgs.join(', ')} and #{dep_count} dep#{'s' unless dep_count == 1} via #{manager_key}"
      log_shell "Downloading", "#{pkg_cmd} -d install #{pkgs.join(' ')}", :sudo => true
      log_shell "Installing", "#{pkg_cmd} install #{pkgs.join(' ')}", :sudo => true
    end

    def update_pkg_lists_if_required
      if !File.exists? '/var/lib/apt/lists/lock'
        log_shell "Looks like apt hasn't been used on this system yet. Updating", "apt-get update", :sudo => true
      else
        list_age = Time.now - File.mtime('/var/lib/apt/lists')
        if list_age > (3600 * 24 * 7) # more than 1 week old
          log_shell "Apt lists are #{list_age.round.xsecs} old. Updating", "apt-get update", :sudo => true
        else
          debug "Apt lists are #{list_age.round.xsecs} old (up to date)."
          true # up to date
        end
      end
    end

    private
    def _has? pkg_name
      failable_shell("dpkg -s #{pkg_name}").stdout.val_for('Status').split(' ').include?('installed')
    end
  end
  end
end
