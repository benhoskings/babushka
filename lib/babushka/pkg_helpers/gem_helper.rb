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
      # The directory in which the binaries from gems are found. This is
      # sometimes different to where `gem` itself is running from.
      env_info.val_for('EXECUTABLE DIRECTORY').p
    end

    def gem_root
      env_info.val_for('INSTALLATION DIRECTORY') / 'gems'
    end
    
    def ruby_path
      env_info.val_for('RUBY EXECUTABLE').p
    end

    def should_sudo?
      super || !File.writable?(gem_root)
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

    def env_info
      @_cached_env_info ||= shell('gem env')
    end
  end
  end
end
