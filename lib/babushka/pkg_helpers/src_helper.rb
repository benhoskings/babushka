module Babushka
  class SrcHelper < PkgHelper
  class << self
    def pkg_type; :src end

    def install_src! cmd, opts = {}
      log_shell "install", cmd, :sudo => (opts[:sudo] || should_sudo?)
    end

    def prefix
      '/usr/local'
    end

  end
  end
end
