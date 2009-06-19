require 'shell_helpers'

class PkgManager
  def self.for_system
    case `uname -s`.chomp
    when 'Darwin'; MacportsHelper
    when 'Linux'; AptHelper
    end.new
  end

  def has? pkg_name
    returning _has?(pkg_name) do |result|
      log "system #{result ? 'has' : 'doesn\'t have'} #{pkg_name} #{pkg_type}"
    end
  end
  def install! *pkgs
    log "Installing #{pkgs.join(', ')} via #{manager_key}"
    sudo "#{pkg_cmd} install #{pkgs.join(' ')}"
  end
  def prefix
    cmd_dir(pkg_cmd).sub(/\/bin\/?$/, '')
  end
  def bin_path
    prefix / 'bin'
  end
  def cmd_in_path? cmd_name
    if (_cmd_dir = cmd_dir(cmd_name)).nil?
      log_error "The '#{cmd_name}' command is not available. You probably need to add #{bin_path} to your PATH."
    else
      returning cmd_dir(cmd_name).starts_with?(prefix) do |result|
        log "#{result ? 'the correct' : 'an incorrect installation of'} '#{cmd_name}' is in use, at #{cmd_dir(cmd_name)}.", :error => !result
      end
    end
  end
end

class MacportsHelper < PkgManager
  def existing_packages
    Dir.glob("/opt/local/var/macports/software/*").map {|i| File.basename i }
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

  def has? pkg_name, version = nil
    versions = versions_of pkg_name
    returning !versions.empty? && (version.nil? || versions.include?(version)) do |result|
      log "system #{result ? 'has' : 'doesn\'t have'} #{pkg_name}#{"-#{version}" unless version.nil?} gem#{" (at #{versions.first})" if version.nil? && result}"
    end
  end

  private

  def versions_of pkg_name
    installed = shell("gem list --local #{pkg_name}").detect {|l| /^#{pkg_name}/ =~ l }
    versions = installed.scan(/.*\(([0-9., ]+)\)/).flatten.first || ''
    versions.split(/[^0-9.]+/)
  end
end
