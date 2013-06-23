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
      [
        ['/etc/debian_version', DebianSystemProfile],
        ['/etc/arch-release',   ArchSystemProfile],
        ['/etc/fedora-release', FedoraSystemProfile],
        ['/etc/centos-release', CentOSSystemProfile],
        ['/etc/redhat-release', RedhatSystemProfile]
      ].select {|(release_file,_)|
        File.exists?(release_file)
      }.map {|(_,profile)|
        profile
      }.first
    end
  end
end
