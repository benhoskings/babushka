module Babushka
  class SystemDetector
    def self.profile_for_host
      (detect_using_uname || UnknownSystem).new
    end

    private

    def self.detect_using_uname
      case ShellHelpers.shell('uname -s')
      when 'Darwin';    OSXSystemProfile
      when 'DragonFly'; DragonFlySystemProfile
      when 'FreeBSD';   FreeBSDSystemProfile
      when 'Linux';     detect_using_release_file || LinuxSystemProfile
      end
    end

    def self.detect_using_release_file
      if File.exists?('/etc/debian_version')
        if File.exists?('/etc/lsb-release') && File.read('/etc/lsb-release')[/ubuntu/i]
          UbuntuSystemProfile
        else
          DebianSystemProfile
        end
      elsif File.exists?('/etc/arch-release')
        ArchSystemProfile
      elsif File.exists?('/etc/fedora-release')
        FedoraSystemProfile
      elsif File.exists?('/etc/centos-release')
        CentOSSystemProfile
      elsif File.exists?('/etc/redhat-release')
        RedhatSystemProfile
      end
    end
  end
end
