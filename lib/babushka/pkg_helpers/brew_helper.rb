module Babushka
  class BrewHelper < PkgHelper
  class << self
    def pkg_type; :brew end
    def pkg_cmd; 'brew' end
    def manager_key; :brew end
    def manager_dep; 'homebrew' end

    def _install! pkgs, opts
      check_for_formulas(pkgs) && pkgs.all? {|pkg|
        log "Installing #{pkg} via #{manager_key}" do
          shell(
            "#{pkg_cmd} install #{cmdline_spec_for pkg} #{opts}",
            :sudo => should_sudo?,
            :log => true,
            :closing_status => :status_only
          )
        end
      }
    end

    def brew_path_for pkg_name
      if active_version = active_version_of(pkg_name)
        installed_pkgs_path / pkg_name / active_version
      end
    end

    def should_sudo?
      super || !File.writable?(installed_pkgs_path)
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

    def active_version_of pkg_name
      (shell("brew version #{pkg_name}") || '').split(' ', 2).last
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
  end
  end
end
