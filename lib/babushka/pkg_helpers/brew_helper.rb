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
          log_error "There is no formula for '#{pkg}' in #{formulas_path} or #{taps_path}." unless result
        }
      }
    end

    def has_formula_for? pkg
      # Tapped formulas need to be mapped to a path
      # e.g. homebrew/dupes/redis.rb => 'homebrew-dupes/**/redis.rb'
      formula = pkg.name.sub('/', '-').sub('/', '/(.*/)?') + '.rb\Z'
      existing_formulas.any? {|path| path.match /#{formula}/ }
    end

    def existing_formulas
      Dir[formulas_path / '*.rb', taps_path / '**/*.rb']
    end

    def active_version_of pkg
      version_info_for(pkg).select {|_,active| active }.map {|v,_| v.to_version }.first
    end

    def versions_of pkg
      version_info_for(pkg).map {|v,_| v.to_version }
    end

    def version_info_for pkg
      pkg_name = pkg.respond_to?(:name) ? pkg.name : pkg
      ShellHelpers.shell("brew info #{pkg_name}").split("\n").collapse(
        %r{^#{Regexp.escape(installed_pkgs_path.to_s)}/#{pkg_name}/}
      ).map {|v|
        [v[/^\S+/], !!v.match(/\*$/)] # [Package version, version is active]
      }.reject {|pair|
        pair.first[/\d|HEAD/].nil? # reject paths that aren't versions, like 'bin' etc
      }
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

    def taps_path
      prefix / 'Library/Taps'
    end

    def homebrew_lib_path
      prefix / 'Library/Homebrew'
    end
  end
  end
end
