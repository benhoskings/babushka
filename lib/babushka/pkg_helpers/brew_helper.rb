module Babushka
  class BrewHelper < PkgHelper
  class << self
    def pkg_type; :brew end
    def pkg_cmd; 'brew' end
    def manager_key; :brew end
    def manager_dep; 'homebrew' end

    def setup_for_install_of dep, pkgs
      log "setup_for_install_of #{dep.name}"
      setup_homebrew_env_if_required
      require_pkg_deps_for dep, pkgs if check_for_formulas pkgs
    end

    def install! pkgs
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


    private

    class LibraryDep
      attr_reader :names
      def initialize *names
        @names = names
      end
    end

    def _has? pkg
      versions_of(pkg).sort.reverse.detect {|version| pkg.matches? version }
    end

    def check_for_formulas pkgs
      pkgs.all? {|pkg|
        returning has_formula_for? pkg do |result|
          log_error "There is no formula for '#{pkg}' in #{formulas_path}." unless result
        end
      }
    end

    def has_formula_for? pkg
      pkg.name.in? existing_formulas
    end

    def existing_formulas
      Dir[formulas_path / '*.rb'].map {|i| File.basename i, '.rb' }
    end

    def versions_of pkg
      pkg_name = pkg.respond_to?(:name) ? pkg.name : pkg
      installed = Dir[
        installed_pkgs_path / pkg_name / '*'
      ].map {|i|
        File.basename i.chomp '/'
      }.map(&:to_version)
    end

    def installed_pkgs_path
      prefix / 'Cellar'
    end
    def formulas_path
      prefix / 'Library/Formula'
    end
    def formula_path_for pkg
      formulas_path / pkg.to_s.end_with('.rb')
    end
    def homebrew_lib_path
      prefix / 'Library/Homebrew'
    end

    def setup_homebrew_env_if_required
      $:.unshift ENV['RUBYLIB'] = homebrew_lib_path unless $:.include? homebrew_lib_path
    end

    def require_pkg_deps_for dep, pkgs
      pkgs.all? {|pkg| require_deps_for dep, pkg }
    end

    def require_deps_for dep, pkg
      IO.readlines(
        formula_path_for pkg
      ).grep(
        /\bLibraryDep\.new/
      ).map {|l|
        eval l.chomp.strip
      }.each {|l|
        log l.inspect
        dep.definer.requires l.names.map {|n| pkg n }
      }
    rescue StandardError => e
      f = formula_path_for pkg
      log_error "#{e.backtrace.first}: #{e.message}"
      log "Check #{(e.backtrace.detect {|l| l[f] } || f).sub(/\:[^:]+$/, '')}."
    end

    def should_sudo
      false
    end
  end
  end
end
