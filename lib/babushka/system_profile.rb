module Babushka
  class SystemProfile
    include ShellHelpers
    extend ShellHelpers

    def matcher
      @matcher ||= SystemMatcher.new(system, flavour, name, pkg_helper_key)
    end

    def matches?(specs)           matcher.matches?(specs) end
    def match_list()              matcher.list end
    def differentiator_for(specs) matcher.distinguish_from(specs) end

    def version_info
      @_version_info ||= get_version_info
    end

    def linux?; system == :linux end
    def osx?;   system == :osx end
    def bsd?;   system == :bsd end

    def pkg_helper; UnknownPkgHelper end
    def pkg_helper_key; pkg_helper.try(:manager_key) end
    def pkg_helper_str; pkg_helper_key.to_s.capitalize end
    # The extension that dynamic libraries are given on this system. On linux
    # libraries are named like 'libssl.so'; on OS X, 'libssl.bundle'.
    def library_ext; 'so' end

    def cpu_type
      shell('uname -p').tap {|result|
        result.replace shell('uname -m') if result[/unknown|\s/]
        # These replacements are taken from PhusionPassenger::PlatformInfo.cpu_architectures
        result.replace 'x86' if result[/^i.86$/]
        result.replace 'x86_64' if result == 'amd64'
      }
    end

    def cpus
      raise "#{self.class}#cpus is unimplemented."
    end

    def total_memory
      raise "#{self.class}#total_memory is unimplemented."
    end

    def public_ip
      raise "#{self.class}#public_ip is unimplemented."
    end

    def description
      [
        (flavour_str unless flavour_str == system_str),
        system_str,
        version,
        ("(#{name_str})" unless name_str.nil?)
      ].compact.join(' ')
    end

    def name
      (SystemDefinitions.names[system][flavour] || {})[release]
    end
    def name_str
      (SystemDefinitions.descriptions[system][flavour] || {})[release]
    end
  end

  class UnknownSystem < SystemProfile
    def description
      "Unknown system"
    end
    def system; :unknown end
    def flavour; :unknown end
    def name; :unknown end
  end

  class OSXSystemProfile < SystemProfile
    def library_ext; 'bundle' end
    def system; :osx end
    def system_str; 'Mac OS X' end
    def flavour; system end
    def flavour_str; system_str end
    def version; version_info.val_for 'ProductVersion' end
    def release; version.match(/^\d+\.\d+/).to_s end
    def get_version_info; shell 'sw_vers' end
    def pkg_helper; BrewHelper end
    def cpus; shell('sysctl -n hw.ncpu').to_i end
    def total_memory; shell("sysctl -a").val_for("hw.memsize").to_i end

    def public_ip
      shell('ifconfig',
        shell('netstat -nr').val_for("default").scan(/\w+$/).first
      ).val_for("inet").scan(/^[\d\.]+/).first
    end

  end

  class BSDSystemProfile < SystemProfile
    def system; :bsd end
    def system_str; 'BSD' end
    def flavour; :unknown end
    def flavour_str; system_str end
    def version; shell 'uname -s' end
    def release; shell 'uname -r' end
    def get_version_info; shell 'uname -v' end
  end

  class DragonFlySystemProfile < BSDSystemProfile
    def system_str; 'DragonFly' end
    def flavour; :dragonfly end
    def pkg_helper; BinPkgSrcHelper end
    def total_memory; shell("sysctl -a").val_for("hw.physmem").to_i end
  end

  class FreeBSDSystemProfile < BSDSystemProfile
    def system_str; 'FreeBSD' end
    def flavour; :freebsd end
    def pkg_helper; BinPortsHelper end
    def total_memory; shell("sysctl -a").val_for("hw.realmem").to_i end
  end

  class LinuxSystemProfile < SystemProfile
    def system; :linux end
    def system_str; 'Linux' end
    def flavour; :unknown end
    def flavour_str; 'Linux' end
    def version; 'unknown' end
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
    def flavour; flavour_str.downcase.to_sym end
    def flavour_str; version_info.val_for 'Distributor ID' end
    def version; version_info.val_for 'Release' end
    def name; version_info.val_for('Codename').to_sym end
    def get_version_info; ensure_lsb_release and shell('lsb_release -a') end
    def ensure_lsb_release
      which('lsb_release') or log("Babushka uses `lsb_release` to learn about debian-based systems.") {
        AptHelper.install!('lsb-release')
      }
    end
    def pkg_helper; AptHelper end
  end

  class RedhatSystemProfile < LinuxSystemProfile
    def flavour; version_info[/^Red Hat/i] ? :redhat : version_info[/^\w+/].downcase.to_sym end
    def flavour_str
      {
        :centos => 'CentOS',
        :redhat => 'Red Hat'
      }[flavour]
    end
    def version; version_info[/release [\d\.]+ \((\w+)\)/i, 1] || version_info[/release ([\d\.]+)/i, 1] end
    def get_version_info; File.read '/etc/redhat-release' end
    def pkg_helper; YumHelper end
  end

  class FedoraSystemProfile < RedhatSystemProfile
    def get_version_info; File.read '/etc/system-release' end
  end

  class ArchSystemProfile < LinuxSystemProfile
    def get_version_info; 'rolling' end
    def pkg_helper; PacmanHelper end
    def flavour; :arch end
    def version; ''; end
  end
end
