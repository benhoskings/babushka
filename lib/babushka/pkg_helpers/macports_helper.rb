module Babushka
  class MacportsHelper < PkgHelper
  class << self
    def existing_packages
      Dir.glob(prefix / "var/macports/software/*").map {|i| File.basename i }
    end
    def pkg_type; :port end
    def pkg_cmd; 'port' end
    def manager_key; :macports end

    def _install! pkgs, opts
      log_shell "Fetching #{pkgs.join(', ')}", "#{pkg_cmd} fetch #{pkgs.join(' ')}", :sudo => true
      super
    end

    private
    def _has? pkg
      pkg.name.split(/\s+/, 2).first.in? existing_packages
    end
  end
  end
end
