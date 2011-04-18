module Babushka
  class SystemProfile
    def self.for_host
      {
        'Linux' => LinuxSystemProfile,
        'Darwin' => OSXSystemProfile
      }[shell('uname -s')].try(:for_flavour)
    end

    def self.for_flavour
      new
    end

    def version_info
      @_version_info ||= get_version_info
    end

    def linux?; false end
    def osx?; false end
    def pkg_helper; nil end
    def pkg_helper_key; pkg_helper.try(:manager_key) end
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

    def total_memory
      raise "#{self.class}#total_memory is unimplemented."
    end

    def description
      [
        (flavour_str unless flavour_str == system_str),
        system_str,
        version,
        "(#{name_str})"
      ].compact.join(' ')
    end

    def name
      (SystemDefinitions.names[system][flavour] || {})[release]
    end
    def name_str
      (SystemDefinitions.descriptions[system][flavour] || {})[release]
    end

    def match_list
      [name, flavour, pkg_helper_key, system, :all].compact
    end

    def matches? specs
      [*specs].any? {|spec| first_nonmatch_for(spec).nil? }
    end

    def first_nonmatch_for spec
      if spec == :all
        nil
      elsif spec.in? SystemDefinitions.all_systems
        spec == system ? nil : :system
      elsif spec.in? PkgHelper.all_manager_keys
        spec == pkg_helper_key ? nil : :pkg_helper
      elsif spec.in? our_flavours
        spec == flavour ? nil : :flavour
      elsif spec.in? our_flavour_names
        spec == name ? nil : :name
      else
        :system
      end
    end

    def differentiator_for specs
      nonmatches = [*specs].map {|spec|
        first_nonmatch_for spec
      }.sort_by {|spec|
        [:system, :flavour, :name].index spec
      }.compact
      send "#{nonmatches.last}_str" unless nonmatches.empty?
    end

    def our_flavours
      SystemDefinitions.names[system].keys
    end
    def our_flavour_names
      SystemDefinitions.names[system][flavour].values
    end

    def flavour_str_map
      # Only required for names that can't be auto-capitalized,
      # e.g. :ubuntu => 'Ubuntu' isn't required.
      {
        :linux => {
          :centos => 'CentOS',
          :redhat => 'Red Hat'
        }
      }
    end

  end

  class OSXSystemProfile < SystemProfile
    def osx?; true end
    def library_ext; 'bundle' end
    def system; :osx end
    def system_str; 'Mac OS X' end
    def flavour; system end
    def flavour_str; system_str end
    def version; version_info.val_for 'ProductVersion' end
    def release; version.match(/^\d+\.\d+/).to_s end
    def get_version_info; shell 'sw_vers' end
    def pkg_helper; BrewHelper end
    def total_memory; shell("sysctl -a").val_for("hw.memsize").to_i end
  end
  
  class LinuxSystemProfile < SystemProfile
    def linux?; true end
    def system; :linux end
    def system_str; 'Linux' end
    def flavour_str; flavour_str_map[system][flavour] end
    def release; version end

    def self.for_flavour
      (detect_using_release_file || LinuxSystemProfile).new
    end

    private

    def self.detect_using_release_file
      {
        'debian_version' => DebianSystemProfile,
        'redhat-release' => RedhatSystemProfile,
        'arch-release'   => ArchSystemProfile,
        # 'gentoo-release' =>
        # 'SuSE-release'   =>
      }.selekt {|release_file, system_profile|
        File.exists? "/etc/#{release_file}"
      }.values.first
    end
  end

  class DebianSystemProfile < LinuxSystemProfile
    def flavour; flavour_str.downcase.to_sym end
    def flavour_str; version_info.val_for 'Distributor ID' end
    def version; version_info.val_for 'Release' end
    def name; version_info.val_for 'Codename' end
    def get_version_info; ensure_lsb_release and shell('lsb_release -a') end
    def ensure_lsb_release
      which('lsb_release') or log("Babushka uses `lsb_release` to learn about debian-based systems.") {
        AptHelper.install!('lsb-release')
      }
    end
    def pkg_helper; AptHelper end
    def total_memory; shell("free -b").val_for("Mem").scan(/^\d+\b/).first.to_i end
  end

  class RedhatSystemProfile < LinuxSystemProfile
    def flavour; version_info[/^Red Hat/i] ? :redhat : version_info[/^\w+/].downcase.to_sym end
    def version; version_info[/release [\d\.]+ \((\w+)\)/i, 1] || version_info[/release ([\d\.]+)/i, 1] end
    def get_version_info; File.read '/etc/redhat-release' end
    def pkg_helper; YumHelper end
  end

  class ArchSystemProfile < LinuxSystemProfile
    def get_version_info; 'rolling' end
    def pkg_helper; PacmanHelper end
    def flavour; :arch end
    def version; ''; end
  end
end
