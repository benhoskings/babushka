module Babushka
  class SystemProfile
    include ShellHelpers
    extend ShellHelpers

    def matcher
      @matcher ||= SystemMatcher.new(system, flavour, codename, pkg_helper_key)
    end

    def matches?(specs) matcher.matches?(specs) end
    def match_list()    matcher.list end

    def definition
      @definition ||= SystemDefinition.new(system, flavour, release)
    end

    def system; system_str.gsub(/[^\w]/, '').downcase.to_sym end
    def flavour; flavour_str.gsub(/[^\w]/, '').downcase.to_sym end

    def codename; definition.codename end
    def codename_str; definition.codename_str end

    def name
      removed! :method_name => 'Babushka.host.name', :instead => 'Babushka.host.codename'
    end
    def name_str
      removed! :method_name => 'Babushka.host.name_str', :instead => 'Babushka.host.codename_str'
    end

    def differentiator_for specs
      differentiator = matcher.differentiator_for(specs)
      send("#{differentiator}_str") unless differentiator.nil?
    end

    def version_info
      @_version_info ||= get_version_info
    end

    def linux?; system == :linux end
    def osx?;   system == :osx end
    def bsd?;   system == :bsd end

    def hostname
      ShellHelpers.shell('hostname -f')
    end

    def pkg_helper_key; pkg_helper.try(:manager_key) end
    def pkg_helper_str; pkg_helper_key.to_s.capitalize end

    def cpu_type
      shell('uname -m').tap {|result|
        # These replacements are taken from PhusionPassenger::PlatformInfo.cpu_architectures
        result.replace 'x86' if result[/^i.86$/]
        result.replace 'x86_64' if result == 'amd64'
      }
    end

    def system_description
      [flavour_str, system_str].uniq.join(' ')
    end

    def description
      [
        system_description,
        version,
        ("(#{codename_str})" unless codename_str.nil?)
      ].compact.join(' ')
    end

    def pkg_helper; UnknownPkgHelper end
    def library_ext; 'so' end # libblah.so on linux, libblah.bundle on OS X, etc.
    def cpus; raise "#{self.class}#cpus is unimplemented." end
    def total_memory; raise "#{self.class}#total_memory is unimplemented." end
    def public_ip; raise "#{self.class}#public_ip is unimplemented." end
  end

  class UnknownSystem < SystemProfile
    def description
      "Unknown system"
    end

    def system; :unknown end
    def system_str; 'Unknown' end
    def flavour; :unknown end
    def flavour_str; 'Unknown' end
    def release; 'unknown' end
    def version; 'unknown' end
    def codename; :unknown end
    def codename_str; 'Unknown' end
  end

  class OSXSystemProfile < SystemProfile
    def library_ext; 'bundle' end
    def system; :osx end
    def system_str; 'Mac OS X' end
    def flavour; system end
    def flavour_str; system_str end
    def version; version_info.val_for 'ProductVersion' end
    def release; version[/^\d+\.\d+/] end
    def get_version_info; shell 'sw_vers' end
    def pkg_helper; BrewHelper end
    def cpus; shell('sysctl -n hw.ncpu').to_i end
    def total_memory; shell("sysctl -n hw.memsize").to_i end

    def public_ip
      shell('ifconfig',
        shell('netstat -nr').val_for("default").scan(/\w+$/).first
      ).val_for("inet").scan(/^[\d\.]+/).first
    end

  end

  class BSDSystemProfile < SystemProfile
    def system; :bsd end
    def system_str; 'BSD' end
    def flavour_str; 'Unknown' end
    def version; shell('uname -r') end
    def release; version.match(/^\d+\.\d+/).to_s end
    def cpus; shell('sysctl -n hw.ncpu').to_i end
    def get_version_info; shell 'uname -v' end
  end

  class DragonFlySystemProfile < BSDSystemProfile
    def flavour_str; 'DragonFly' end
    def pkg_helper; BinPkgSrcHelper end
    def total_memory; shell("sysctl -n hw.physmem").to_i end
  end

  class FreeBSDSystemProfile < BSDSystemProfile
    def system_description; flavour_str end # Not 'FreeBSD BSD'
    def flavour_str; 'FreeBSD' end
    def release; version end # So '9.0-RELEASE' doesn't become '9.0'
    def pkg_helper; BinPortsHelper end
    def total_memory; shell("sysctl -n hw.realmem").to_i end
  end

  class LinuxSystemProfile < SystemProfile
    def system_str; 'Linux' end
    def flavour_str; 'Unknown' end
    def version; nil end
    def release; version end
    def cpus; shell("cat /proc/cpuinfo | grep '^processor\\b' | wc -l").to_i end
    def total_memory; shell("free -b").val_for("Mem").scan(/^\d+\b/).first.to_i end

    def public_ip
      shell('ifconfig',
        shell('netstat -nr').val_for("0.0.0.0").scan(/\w+$/).first
      ).val_for("inet addr").scan(/^[\d\.]+/).first
    end
  end

  class DebianSystemProfile < LinuxSystemProfile
    def flavour_str; 'Debian' end
    def version; version_info end
    def release; version[/^(\d+)/, 1] end
    def codename_str; codename.to_s end # They're named just like our symbols; no need to duplicate in SystemDefinition.

    def get_version_info; File.read('/etc/debian_version') end
    def pkg_helper; AptHelper end
  end

  class UbuntuSystemProfile < LinuxSystemProfile
    def flavour_str; 'Ubuntu' end
    def version; version_info.val_for('DISTRIB_RELEASE') end

    def get_version_info; File.read('/etc/lsb-release') end
    def pkg_helper; AptHelper end
  end

  class RedhatSystemProfile < LinuxSystemProfile
    def flavour_str; 'Red Hat' end

    def version
      version_info[/release ([\d\.]+)/i, 1]
    end
    def release
      version[/^(\d+)/, 1]
    end

    def get_version_info; File.read('/etc/redhat-release') end
    def pkg_helper; YumHelper end
  end

  class CentOSSystemProfile < RedhatSystemProfile
    def flavour_str; 'CentOS' end
    def get_version_info; File.read('/etc/centos-release') end
  end

  class FedoraSystemProfile < RedhatSystemProfile
    def flavour_str; 'Fedora' end
    def get_version_info; File.read('/etc/fedora-release') end
  end

  class ArchSystemProfile < LinuxSystemProfile
    def flavour_str; 'Arch' end
    def pkg_helper; PacmanHelper end


    # Arch uses rolling versions and doesn't assign version numbers.
    def get_version_info; 'rolling' end
    def version; nil end
  end

    class SuseSystemProfile < LinuxSystemProfile
    def flavour_str; 'openSUSE' end
    def version
      version_info[/([\d\.]+)/i, 1]
    end
    def release
      version[/^(\d+)/, 1]
    end
    def get_version_info; File.read('/etc/SuSE-release') end
    def pkg_helper; ZypperHelper end
  end
end
