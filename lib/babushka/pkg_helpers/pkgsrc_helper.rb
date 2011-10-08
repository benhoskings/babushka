module Babushka
  class PkgSrcHelper < PkgHelper
  class << self
    def existing_packages
      shell("pkg_info -a").lines.to_a.collect!{ |i| i.split(/\s+/)[0] }
    end

    def pkg_binary; 'pkg_radd' end
    def pkg_cmd; pkg_binary end
    def pkg_type; :pkg end
    def manager_key; :pkgsrc end

    def update_pkg_lists_if_required
      if !File.exists? pkg_list_dir
        update_pkg_lists "Looks like pkg summary hasn't been fetched on this system yet. Updating"
      else
        super
      end
    end

    def pkg_update_timeout
      3600 * 24 * 14 # 2 weeks
    end

    def pkg_list_dir
      '/usr/pkgsrc/pkg_summary'.p
    end

    def pkg_update_command
      "pkg_search -d"
    end

    def _install! pkgs, opts
      log_shell "Installing #{pkgs.join(', ')}", "pkg_radd #{pkgs.join(' ')}", :sudo => should_sudo?
    end

    private

    def _has? pkg
      existing_packages.any?{ |i| i.match(/#{pkg}/)}
    end

  end
  end
end
