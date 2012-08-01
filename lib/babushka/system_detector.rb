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
      {
        'debian_version' => DebianSystemProfile,
        'redhat-release' => RedhatSystemProfile,
        'arch-release'   => ArchSystemProfile,
        'system-release' => FedoraSystemProfile,
        # 'gentoo-release' =>
        # 'SuSE-release'   =>
      }.selekt {|release_file, system_profile|
        File.exists? "/etc/#{release_file}"
      }.values.first
    end
  end
end
