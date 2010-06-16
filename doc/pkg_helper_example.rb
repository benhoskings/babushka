module Babushka
  class ExampleHelper < PkgHelper
  class << self
    def pkg_type; :deb end # a description of the type of package, that makes sense in the context of, e.g. "the zsh deb"
    def pkg_cmd; "#{pkg_binary} -qyu" end # The full command to run the package manager
    def pkg_binary; "apt-get" end # The name of the binary itself
    def manager_key; :apt end # How packages should be specified in deps, e.g. "via :apt, 'zsh'"

    private

    def _install! pkgs, opts
      # Unconditionally install +pkgs+.
    end

    def _has? pkg_name
      # Return a boolean - whether pkg_name is installed.
    end

  end
  end
end
