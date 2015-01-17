module Babushka
  class NpmHelper < PkgHelper
  class << self
    def pkg_type; :npm end
    def pkg_cmd; "#{pkg_binary} --color false" end
    def pkg_binary; "npm" end
    def manager_key; :npm end
    def manager_dep; 'core:npm' end

    def should_sudo?
      !shell("npm config get prefix").p.writable_real?
    end

    private

    def has_pkg? pkg
      # Some example output:
      #   socket.io@0.6.15      =rauchg active installed remote
      shell("#{pkg_cmd} ls -g").split("\n").grep(
        /^\W*#{Regexp.escape(pkg.name)}\@/
      ).any? {|match|
        pkg.matches? match.scan(/\@(.*)$/).flatten.first
      }
    end

    def install_pkgs! pkgs, opts
      pkgs.each {|pkg|
        log_shell "Installing #{pkg} via #{manager_key}",
          "#{pkg_cmd} install -g #{cmdline_spec_for pkg} #{opts}",
          :sudo => should_sudo?
      }
    end

    def cmdline_spec_for pkg
      if pkg.version.nil?
        # e.g. 'socket.io'
        "'#{pkg.name}'"
      else
        # e.g. 'socket.io@==0.12.0'
        "'#{pkg.name}@#{pkg.version.operator}#{pkg.version.version}'"
      end
    end

  end
  end
end
