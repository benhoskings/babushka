module Babushka
  class GemHelper < PkgHelper
  class << self
    def pkg_type; :gem end
    def pkg_cmd; 'gem' end
    def manager_key; :gem end
    def manager_dep; 'core:rubygems' end

    def install! pkgs, opts = nil
      super.tap {
        shell!('rbenv rehash') if Babushka.ruby.rbenv?
      }
    end

    def gem_path_for gem_name, version = nil
      unless (detected_version = has?(Babushka.VersionOf(gem_name, version), :log => false)).nil?
        Babushka.ruby.gem_dir / Babushka.VersionOf(gem_name, detected_version)
      end
    end

    def bin_path
      Babushka.ruby.bin_dir
    end

    def should_sudo?
      super || (Babushka.ruby.gem_dir.exists? && !Babushka.ruby.gem_dir.writable_real?)
    end


    private

    def has_pkg? pkg
      versions_of(pkg).sort.reverse.detect {|version| pkg.matches? version }
    end

    def install_pkgs! pkgs, opts
      pkgs.each {|pkg|
        log_shell "Installing #{pkg} via #{manager_key}",
          "#{pkg_cmd} install #{cmdline_spec_for pkg} #{opts}",
          :sudo => should_sudo?
      }
    end

    def versions_of pkg
      pkg_name = pkg.respond_to?(:name) ? pkg.name : pkg
      gemspecs_for(pkg_name).select {|path|
        Gem::Specification::load(path).version
      }.map {|i|
        File.basename(i).scan(/^#{pkg_name}-(.*).gemspec$/).flatten.first
      }.map {|i|
        i.to_version
      }.sort
    end

    def gemspecs_for pkg_name
      Babushka.ruby.gemspec_dir.glob("#{pkg_name}-*.gemspec")
    end
  end
  end
end
