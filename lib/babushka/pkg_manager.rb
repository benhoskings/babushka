module Babushka
  class PkgManager
  class << self
    include ShellHelpers

    def for_system
      {
        'Darwin' => MacportsHelper,
        'Linux' => AptHelper
      }[`uname -s`.chomp]
    end

    def manager_dep
      manager_key.to_s
    end

    def has? pkg_name, opts = {}
      returning _has?(pkg_name) do |result|
        unless opts[:log] == false
          log "system #{result ? 'has' : 'doesn\'t have'} #{pkg_name} #{pkg_type}", :as => (result ? :ok : nil)
        end
      end
    end
    def install! pkgs
      log_shell "Installing #{pkgs.join(', ')} via #{manager_key}", "#{pkg_cmd} install #{pkgs.join(' ')}", :sudo => true
    end
    def prefix
      cmd_dir(pkg_cmd.split(' ', 2).first).sub(/\/bin\/?$/, '')
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
      pkg.name.in? existing_packages
    end
  end
  end

  class AptHelper < PkgManager
  class << self
    def pkg_type; :deb end
    def pkg_cmd; 'apt-get -y' end
    def manager_key; :apt end

    def install! pkgs
      package_count = sudo("#{pkg_cmd} -s install #{pkgs.join(' ')}").split.grep(/^Inst\b/).length
      dep_count = package_count - pkgs.length

      log "Installing #{pkgs.join(', ')} and #{package_count} dep#{'s' unless dep_count == 1} via #{manager_key}"
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
        File.join gem_root, ver(gem_name, detected_version).to_s
      end
    end

    def gem_root
      File.join shell('gem env gemdir'), 'gems'
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
end
