module Babushka
  class BrewHelper < PkgHelper
  class << self
    def pkg_type; :brew end
    def pkg_cmd; 'brew' end
    def manager_key; :brew end
    def manager_dep; 'homebrew' end

    def install! pkgs
      install_packages! pkgs if pkgs.all? {|pkg|
        returning has_formula_for? pkg do |result|
          log_error "There is no formula for '#{pkg}' in #{formulas_prefix}." unless result
        end
      }
    end

    private

    def install_packages! pkgs
      pkgs.all? {|pkg|
        log_shell_with_a_block_to_scan_stdout_for_apps_that_have_broken_return_values(
          "Installing #{pkg} via #{manager_key}",
          "#{pkg_cmd} install #{cmdline_spec_for pkg}",
          :sudo => should_sudo
        ) {|shell|
          shell.result && shell.stdout["\033[1;31m==>\033[0;0;1m Error\033[0;0m:"].nil?
        }
      }
    end

    def _has? pkg
      versions_of(pkg).sort.reverse.detect {|version| pkg.matches? version }
    end

    def has_formula_for? pkg
      pkg.name.in? existing_formulas
    end

    def existing_formulas
      Dir[formulas_prefix / '*.rb'].map {|i| File.basename i, '.rb' }
    end

    def versions_of pkg
      pkg_name = pkg.respond_to?(:name) ? pkg.name : pkg
      installed = Dir[
        installed_pkgs_prefix / pkg_name / '*'
      ].map {|i|
        File.basename i.chomp '/'
      }.map(&:to_version)
    end

    def installed_pkgs_prefix
      prefix / 'Cellar'
    end

    def formulas_prefix
      prefix / 'Library/Formula'
    end

    def should_sudo
      false
    end
  end
  end
end
