module Babushka
  class PacmanHelper < PkgHelper
  class << self
    def pkg_type; :package end # a description of the type of package, that makes sense in the context of, e.g. "the zsh deb"
    def pkg_cmd; "#{pkg_binary}" end # The full command to run the package manager
    def pkg_binary; "pacman" end # The name of the binary itself
    def manager_key; :pacman end # How packages should be specified in deps, e.g. "via :apt, 'zsh'"

    private

    def has_pkg? pkg_name
      shell?("#{pkg_cmd} --query #{pkg_name}")
    end

    # NOTE By default, Arch has sudo's `tty_tickets` option enabled. This will
    # result in sudo asking for your password every single time it's run from
    # Babushka. If you find this annoying, please refer to
    # https://wiki.archlinux.org/index.php/Sudo#Disable_per-terminal_sudo
    #
    # tl;dr - Add the following line to /etc/sudoers:
    #         Defaults !tty_tickets
    def install_pkgs! pkgs, opts
      log_shell "Syncing packages", "#{pkg_cmd} --sync --noconfirm --noprogressbar #{pkgs.join(' ')}", :sudo => should_sudo?
    end

    def pkg_update_command
      "#{pkg_cmd} --sync --refresh"
    end

    def pkg_list_dir
      '/var/lib/pacman/sync'.p
    end

    def pkg_update_timeout
      3600 # 1 hour
    end

  end
  end
end
