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
        gem_root / ver(gem_name, detected_version)
      end
    end

    def bin_path
      # The directory in which the actual gem binary is found. The gem-installed
      # binaries will be in the same location. (/usr/local/bin/ruby, etc, are
      # sometimes symlinks.)
      @_cached_bin_path ||= which('gem').p.readlink.dir
    end

    def gem_root
      @_cached_gem_root ||= shell('gem env gemdir') / 'gems'
    end
    
    # The directory where gem binaries are stored.
    def bin_root
      @bin_root ||= shell('gem env').split(/\n/).detect { |line|
        line[/EXECUTABLE DIRECTORY/]
      }.gsub(/^.*EXECUTABLE DIRECTORY:\s+/, '')
    end
    
    def should_sudo?
      !(File.writable?(gem_root) && File.writable?(bin_root))
    end


    private

    def _has? pkg
      versions_of(pkg).sort.reverse.detect {|version| pkg.matches? version }
    end

    def versions_of pkg
      pkg_name = pkg.respond_to?(:name) ? pkg.name : pkg
      gem_root.glob("#{pkg_name}-*").map {|i|
        File.basename i
      }.map {|i|
        i.gsub(/^#{pkg_name}-/, '').to_version
      }.sort
    end
  end
  end
end
