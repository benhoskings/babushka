module Babushka
  class GemHelper < PkgHelper
  class << self
    def pkg_type; :gem end
    def pkg_cmd; 'gem' end
    def manager_key; :gem end
    def manager_dep; 'rubygems' end

    def _install! pkgs, opts
      pkgs.each {|pkg|
        log_shell "Installing #{pkg} via #{manager_key}",
          "#{pkg_cmd} install #{cmdline_spec_for pkg} #{opts}",
          :sudo => should_sudo?
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
    def should_sudo?
      super || !File.writable?(gem_root)
    end
  end
  end
end
