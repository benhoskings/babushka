module Babushka
  class BrewHelper < PkgHelper
  class << self
    def pkg_type; :brew end
    def pkg_cmd; 'brew' end
    def manager_key; :brew end
    def manager_dep; 'homebrew' end

    def update_pkg_lists_if_required
      super.tap {|result|
        pkg_list_dir.touch if result
      }
    end

    def brew_path_for pkg_name
      if active_version = active_version_of(pkg_name)
        installed_pkgs_path / pkg_name / active_version
      end
    end

    def should_sudo?
      super || !installed_pkgs_path.hypothetically_writable?
    end

    private

    def has_pkg? pkg
      versions_of(pkg).sort.reverse.detect {|version| pkg.matches? version }
    end

    def install_pkgs! pkgs, opts
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

    def check_for_formulas pkgs
      pkgs.all? {|pkg|
        has_formula_for?(pkg).tap {|result|
          log_error "There is no formula for '#{pkg}' in #{formulas_path}." unless result
        }
      }
    end

    def has_formula_for? pkg
      existing_formulas.include? pkg.name
    end

    def existing_formulas
      Dir[formulas_path / '*.rb'].map {|i| File.basename i, '.rb' }
    end

    def active_version_of pkg_name
      shell("brew info #{pkg_name}").split("\n\n", 2).first.split("\n").map {|i|
        i.scan(/^#{Regexp.escape(installed_pkgs_path.to_s.end_with('/'))}([^\s]+)/)
      }.flatten.select {|i|
        i[/\d/] # For it to be a version, it has to have at least 1 digit.
      }.map {|i|
        Babushka.VersionOf i.split('/', 2)
      }.max.version
    end

    def versions_of pkg
      pkg_name = pkg.respond_to?(:name) ? pkg.name : pkg
      Dir[
        installed_pkgs_path / pkg_name / '*'
      ].map {|i|
        File.basename i.chomp('/')
      }.reject {|i|
        i[/\d|HEAD/].nil? # reject paths that aren't versions, like 'bin' etc
      }.map(&:to_version)
    end

    def pkg_update_timeout
      3600 # 1 hour
    end
    def pkg_list_dir
      prefix
    end

    def installed_pkgs_path
      prefix / 'Cellar'
    end
    def formulas_path
      prefix / 'Library/Formula'
    end
    def homebrew_lib_path
      prefix / 'Library/Homebrew'
    end
  end
  end
end
