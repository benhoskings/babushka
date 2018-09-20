module Babushka
  class BrewHelper < PkgHelper
  class << self
    def pkg_type; :brew end
    def pkg_cmd; 'brew' end
    def manager_key; :brew end
    def manager_dep; 'core:homebrew' end

    def update_pkg_lists_if_required
      super.tap {|result|
        pkg_list_dir.touch if result
      }
    end

    def should_sudo?
      super || !installed_pkgs_path.hypothetically_writable?
    end

    private

    def has_pkg? pkg
      versions_of(pkg).sort.reverse.detect { |version| pkg.matches? version }
    end

    def install_pkgs! pkgs, opts
      pkgs.all? {|pkg|
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

    def versions_of pkg
      version_info_for(pkg).map {|v,_| v.to_version }
    end

    def version_info_for pkg
      pkg_name = pkg.respond_to?(:name) ? pkg.name : pkg
      pkg_info = ShellHelpers.shell("brew info #{pkg_name}")

      if pkg_info.nil?
        []
      else
        pkg_info.split("\n").collapse(
          # Collapse e.g.
          #   "/usr/local/Cellar/heroku/7.7.10 (51,810 files, 218MB) *"
          # into:
          #   "7.7.10 (51,810 files, 218MB) *"
          #
          # This makes for easier extraction of the version and active package
          # details in the next block.
          #
          # To ensure this works for packages named by their taps, split the
          # package name on the last slash so e.g. `heroku/brew/heroku` becomes
          # just `heroku`.
          %r{^#{Regexp.escape(installed_pkgs_path.to_s)}/#{pkg_name.split("/").last}/}
        ).map {|v|
          [v[/^\S+/], !!v.match(/\*$/)] # [Package version, version is active?]
        }.reject {|pair|
          pair.first[/\d|HEAD/].nil? # reject paths that aren't versions, like 'bin' etc
        }
      end
    end

    def pkg_update_timeout
      3600 # 1 hour
    end

    def pkg_list_dir
      homebrew_component_path
    end

    def installed_pkgs_path
      prefix / 'Cellar'
    end

    def homebrew_component_path
      if Dir.exist?(prefix / "Library/Formula") # Indicates a legacy installation
        prefix
      else
        prefix / "Homebrew"
      end
    end
  end
  end
end
