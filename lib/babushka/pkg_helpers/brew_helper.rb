module Babushka
  class BrewHelper < PkgHelper
  class << self
    def pkg_type; :brew end
    def pkg_cmd; 'brew' end
    def manager_key; :brew end
    def manager_dep; 'homebrew' end

    def install! pkgs
      pkgs.all? {|pkg|
        log_shell "Installing #{pkg} via #{manager_key}",
          "#{pkg_cmd} install #{cmdline_spec_for pkg}",
          :sudo => should_sudo
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
