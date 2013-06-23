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
        ['debian_version', DebianSystemProfile],
        ['arch-release',   ArchSystemProfile],
        ['system-release', FedoraSystemProfile],
        ['centos-release', CentOSSystemProfile],
        ['redhat-release', RedhatSystemProfile]
      ].select {|(release_file,_)|
        File.exists?("/etc/#{release_file}")
      }.map {|(_,profile)|
        profile
      }.first
    end
  end
end
