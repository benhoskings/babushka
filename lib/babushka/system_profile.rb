module Babushka
  class SystemProfile
    attr_reader :version_info

    def self.for_host
      system = {
        'Linux' => LinuxSystemProfile,
        'Darwin' => OSXSystemProfile
      }[shell('uname -s')]
      system.for_flavour unless system.nil?
    end

    def self.for_flavour
      new
    end

    def initialize
      setup
      @version_info = get_version_info
    end

    def linux?; false end
    def osx?; false end
    def pkg_helper; nil end
    def setup; true end
    def pkg_helper_key; pkg_helper.manager_key unless pkg_helper.nil? end
    # The extension that dynamic libraries are given on this system. On linux
    # libraries are named like 'libssl.so'; on OS X, 'libssl.bundle'.
    def library_ext; 'so' end

    def cpu_type
      shell('uname -p').tap {|result|
        result.replace shell('uname -m') if result[/unknown|\s/]
      }
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
      elsif spec.in? all_systems
        spec == system ? nil : :system
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

    def all_systems
      SystemDefinitions.names.keys
    end
    def all_flavours
      SystemDefinitions.names.values.map(&:keys).flatten
    end
    def all_names
      SystemDefinitions.names.values.map(&:values).map {|s| s.map(&:values) }.flatten
    end
    def our_flavours
      SystemDefinitions.names[system].keys
    end
    def our_flavour_names
      SystemDefinitions.names[system][flavour].values
    end
    def all_tokens
      all_systems + PkgHelper.all_manager_keys + all_flavours + all_names
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
  end
  
  class LinuxSystemProfile < SystemProfile
    def linux?; true end
    def system; :linux end
    def system_str; 'Linux' end
    def flavour_str; flavour_str_map[system][flavour] end
    def release; version end

    def self.for_flavour
      unless (detected_flavour = detect_using_release_file).nil?
        Babushka.const_get("#{detected_flavour.capitalize}SystemProfile").new
      end
    end

    private

    def self.detect_using_release_file
      %w[
        debian_version
        redhat-release
        gentoo-release
        SuSE-release
        arch-release
      ].select {|release_file|
        File.exists? "/etc/#{release_file}"
      }.map {|release_file|
        release_file.sub(/[_\-](version|release)$/, '')
      }.first
    end
  end

  class DebianSystemProfile < LinuxSystemProfile
    def flavour; flavour_str.downcase.to_sym end
    def flavour_str; version_info.val_for 'Distributor ID' end
    def version; version_info.val_for 'Release' end
    def setup
      which('lsb_release') or log("Babushka uses `lsb_release` to learn about debian-based systems.") {
        AptHelper.install!('lsb-release')
      }
    end
    def get_version_info; shell 'lsb_release -a' end
    def pkg_helper; AptHelper end
  end

  class RedhatSystemProfile < LinuxSystemProfile
    def flavour; version_info[/^Red Hat/i] ? :redhat : version_info[/^\w+/].downcase.to_sym end
    def version; version_info[/release [\d\.]+ \((\w+)\)/i, 1] || version_info[/release ([\d\.]+)/i, 1] end
    def get_version_info; File.read '/etc/redhat-release' end
    def pkg_helper; YumHelper end
  end
end
