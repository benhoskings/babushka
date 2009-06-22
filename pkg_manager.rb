require 'shell_helpers'

class PkgManager
  def self.for_system
    case `uname -s`.chomp
    when 'Darwin'; MacportsHelper
    when 'Linux'; AptHelper
    end.new
  end

  def manager_dep
    manager_key.to_s
  end

  def has? pkg_name
    returning _has?(pkg_name) do |result|
      log "system #{result ? 'has' : 'doesn\'t have'} #{pkg_name} #{pkg_type}", :as => :ok
    end
  end
  def install! *pkgs
    log "Installing #{pkgs.join(', ')} via #{manager_key}"
    sudo "#{pkg_cmd} install #{pkgs.join(' ')}"
  end
  def prefix
    cmd_dir(pkg_cmd.split(' ', 2).first).sub(/\/bin\/?$/, '')
  end
  def bin_path
    prefix / 'bin'
  end
  def cmd_in_path? cmd_name
    if (_cmd_dir = cmd_dir(cmd_name)).nil?
      log_error "The '#{cmd_name}' command is not available. You probably need to add #{bin_path} to your PATH."
    else
      cmd_dir(cmd_name).starts_with?(prefix)
    end
  end
end

class MacportsHelper < PkgManager
  def existing_packages
    Dir.glob(prefix / "var/macports/software/*").map {|i| File.basename i }
  end
  def pkg_type; :port end
  def pkg_cmd; 'port' end
  def manager_key; :macports end

  private
  def _has? pkg_name
    pkg_name.in? existing_packages
  end
end

class AptHelper < PkgManager
  def pkg_type; :deb end
  def pkg_cmd; 'apt-get -y' end
  def manager_key; :apt end

  private
  def _has? pkg_name
    shell("dpkg -s #{pkg_name}")
  end
end

class GemHelper < PkgManager
  def pkg_type; :gem end
  def pkg_cmd; 'gem' end
  def manager_key; :gem end
  def manager_dep; 'rubygems' end

  def has? pkg_name, requested_version = nil
    versions = versions_of pkg_name
    version = (version.nil? ? versions : versions & [version]).last
    returning version do |result|
      pkg_spec = "#{pkg_name}#{"-#{requested_version}" unless requested_version.nil?}"
      if result
        log_ok "system has #{pkg_spec} gem#{" (at #{version})" if requested_version.nil?}"
      else
        log "system doesn't have #{pkg_spec} gem"
      end
    end
  end

  private

  def versions_of pkg_name
    installed = shell("gem list --local #{pkg_name}").detect {|l| /^#{pkg_name}/ =~ l }
    versions = (installed || "#{pkg_name} ()").scan(/.*\(([0-9., ]*)\)/).flatten.first || ''
    versions.split(/[^0-9.]+/).sort
  end
end
