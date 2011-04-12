module Babushka
  class PacmanHelper < PkgHelper
  class << self
    def pkg_type; :package end # a description of the type of package, that makes sense in the context of, e.g. "the zsh deb"
    def pkg_cmd; "#{pkg_binary}" end # The full command to run the package manager
    def pkg_binary; "pacman" end # The name of the binary itself
    def manager_key; :pacman end # How packages should be specified in deps, e.g. "via :apt, 'zsh'"

    private

    def _install! pkgs, opts
      log_shell "Downloading", "#{pkg_cmd} -S --noconfirm #{pkgs.join(' ')}", :sudo => should_sudo?
      super
    end

    def _has? pkg_name
      failable_shell("pacman -Q #{pkg_name}").stderr !~ /not found$/
    end
  end
  end
end
