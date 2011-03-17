module Babushka
  class PipHelper < PkgHelper
  class << self
    def pkg_type; :pip end
    def pkg_cmd; pkg_binary end
    def pkg_binary; "pip" end
    def manager_key; :pip end

    private

    def _install! pkgs, opts
      log_shell "Installing #{pkgs.to_list} via #{manager_key}", "#{pkg_cmd} install #{pkgs.join(' ')} #{opts}", :sudo => should_sudo?
    end

    def _has? pkg
      # Some example output:
      #   gunicorn==0.12.0
      failable_shell("pip freeze '#{pkg.name}'").stdout.split("\n").select {|line|
        line[/^#{Regexp.escape(pkg.name)}\=\=/]
      }.any? {|match|
        pkg.matches? match.scan(/\=\=(.*)$/).flatten.first
      }
    end

    def cmdline_spec_for pkg
      if pkg.version.blank?
        # e.g. 'gunicorn'
        "'#{pkg.name}'"
      else
        # e.g. 'gunicorn==0.12.0'
        "'#{pkg.name}#{pkg.version.operator}#{pkg.version.version}'"
      end
    end

    def should_sudo?
      !File.writable?(bin_path / pkg_binary)
    end

  end
  end
end
