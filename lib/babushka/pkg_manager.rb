module Babushka
  class PkgManager
  class << self
    include ShellHelpers

    def pkg_binary; pkg_cmd end

    def for_system
      {
        'Darwin' => MacportsHelper,
        'Linux' => AptHelper
      }[`uname -s`.chomp]
    end

    def manager_dep
      manager_key.to_s
    end

    def has? pkg, opts = {}
      returning _has?(pkg) do |matching_version|
        matching_pkg = ver(pkg.name, (matching_version if matching_version.is_a?(VersionStr)))
        unless opts[:log] == false
          log "system #{matching_version ? "has" : "doesn't have"} #{matching_pkg} #{pkg_type}", :as => (:ok if matching_version)
        end
      end
    end
    def install! pkgs
      log_shell "Installing #{pkgs.join(', ')} via #{manager_key}", "#{pkg_cmd} install #{pkgs.join(' ')}", :sudo => true
    end
    def prefix
      cmd_dir(pkg_binary).sub(/\/bin\/?$/, '')
    end
    def bin_path
      prefix / 'bin'
    end
    def cmd_in_path? cmd_name
      if (_cmd_dir = cmd_dir(cmd_name)).nil?
        log_error "The '#{cmd_name}' command is not available. You probably need to add #{bin_path} to your PATH."
      else
        cmd_dir(cmd_name).starts_with?(prefix)
      end
    end
    def should_sudo
      true
    end
  end
  end

  class MacportsHelper < PkgManager
  class << self
    def existing_packages
      Dir.glob(prefix / "var/macports/software/*").map {|i| File.basename i }
    end
    def pkg_type; :port end
    def pkg_cmd; 'port' end
    def manager_key; :macports end

    def install! pkgs
      log_shell "Fetching #{pkgs.join(', ')}", "#{pkg_cmd} fetch #{pkgs.join(' ')}", :sudo => true
      super
    end

    private
    def _has? pkg
      pkg.name.split(/\s+/, 2).first.in? existing_packages
    end
  end
  end

  class AptHelper < PkgManager
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

    private
    def _has? pkg_name
      failable_shell("dpkg -s #{pkg_name}").stdout.val_for('Status').split(' ').include?('installed')
    end
  end
  end

  class GemHelper < PkgManager
  class << self
    def pkg_type; :gem end
    def pkg_cmd; 'gem' end
    def manager_key; :gem end
    def manager_dep; 'rubygems' end

    def install! pkgs
      pkgs.each {|pkg|
        log_shell "Installing #{pkg} via #{manager_key}", "#{pkg_cmd} install #{pkg.name}#{" --version '#{pkg.version}'" unless pkg.version.blank?}", :sudo => true
      }
    end

    def gem_path_for gem_name, version = nil
      unless (detected_version = has?(ver(gem_name, version), :log => false)).nil?
        gem_root / ver(gem_name, detected_version).to_s
      end
    end

    def gem_root
      shell('gem env gemdir') / 'gems'
    end


    private

    def _has? pkg
      versions_of(pkg).sort.reverse.detect {|version| pkg.matches? version }
    end

    def versions_of pkg
      pkg_name = pkg.respond_to?(:name) ? pkg.name : pkg
      installed = shell("gem list --local #{pkg_name}").split("\n").detect {|l| /^#{pkg_name}\b/ =~ l }
      versions = (installed || "#{pkg_name} ()").scan(/.*\(([0-9., ]*)\)/).flatten.first || ''
      versions.split(/[^0-9.]+/).sort.map(&:to_version)
    end
  end
  end

  class BrewHelper < PkgManager
  class << self
    def pkg_type; :brew end
    def pkg_cmd; 'brew' end
    def manager_key; :brew end
    def manager_dep; 'homebrew' end

    def install! pkgs
      pkgs.each {|pkg|
        log_shell "Installing #{pkg} via #{manager_key}", "#{pkg_cmd} install #{pkg.name}#{" --version '#{pkg.version}'" unless pkg.version.blank?}", :sudo => should_sudo
      }
    end

    private

    def _has? pkg
      versions_of(pkg).sort.reverse.detect {|version| pkg.matches? version }
    end

    def versions_of pkg
      pkg_name = pkg.respond_to?(:name) ? pkg.name : pkg
      installed = Dir[
        prefix / 'Cellar' / pkg_name / '*'
      ].map {|i|
        File.basename i.chomp '/'
      }.map(&:to_version)
    end
    def should_sudo
      false
    end
  end
  end
end
