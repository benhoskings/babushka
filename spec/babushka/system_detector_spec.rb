require 'spec_helper'

RSpec.describe Babushka::SystemDetector do
  subject {
    Babushka::SystemDetector.profile_for_host
  }

  describe '.for_host' do
    it "should return OSXSystemProfile on Darwin boxes" do
      expect(Babushka::ShellHelpers).to receive(:shell).with("uname -s").and_return("Darwin")
      expect(subject).to be_an_instance_of(Babushka::OSXSystemProfile)
    end
    it "should return UnknownSystem on unknown boxes" do
      expect(Babushka::ShellHelpers).to receive(:shell).with("uname -s").and_return("LolOS")
      expect(subject).to be_an_instance_of(Babushka::UnknownSystem)
    end
    context "on BSD boxes" do
      it "should return DragonFlySystemProfile on Dragonfly boxes" do
        expect(Babushka::ShellHelpers).to receive(:shell).with("uname -s").and_return("DragonFly")
        expect(subject).to be_an_instance_of(Babushka::DragonFlySystemProfile)
      end
      it "should return FreeBSDSystemProfile on FreeBSD boxes" do
        expect(Babushka::ShellHelpers).to receive(:shell).with("uname -s").and_return("FreeBSD")
        expect(subject).to be_an_instance_of(Babushka::FreeBSDSystemProfile)
      end
    end
    context "on Linux boxes" do
      before {
        expect(Babushka::ShellHelpers).to receive(:shell).with("uname -s").and_return("Linux")
        allow(File).to receive(:exists?).and_return(false)
      }
      it "should return DebianSystemProfile on Debian boxes" do
        expect(File).to receive(:exists?).with("/etc/debian_version").and_return(true)
        expect(File).to receive(:exists?).with("/etc/lsb-release").and_return(false)
        expect(File).to receive(:exists?).with("/etc/os-release").and_return(true)
        expect(File).to receive(:read).with("/etc/os-release").and_return('ID=debian')
        expect(subject).to be_an_instance_of(Babushka::DebianSystemProfile)
      end
      it "should return UbuntuSystemProfile on Ubuntu boxes" do
        expect(File).to receive(:exists?).with("/etc/debian_version").and_return(true)
        expect(File).to receive(:exists?).with("/etc/lsb-release").and_return(true)
        expect(File).to receive(:read).with("/etc/lsb-release").and_return('Ubuntu')
        expect(subject).to be_an_instance_of(Babushka::UbuntuSystemProfile)
      end
      it "should return RaspbianSystemProfile on Raspbian boxes" do
        expect(File).to receive(:exists?).with("/etc/debian_version").and_return(true)
        expect(File).to receive(:exists?).with("/etc/lsb-release").and_return(false)
        expect(File).to receive(:exists?).with("/etc/os-release").and_return(true)
        expect(File).to receive(:read).with("/etc/os-release").and_return('ID=raspbian')
        expect(subject).to be_an_instance_of(Babushka::RaspbianSystemProfile)
      end
      it "should return ArchSystemProfile on Arch boxes" do
        expect(File).to receive(:exists?).with("/etc/arch-release").and_return(true)
        expect(subject).to be_an_instance_of(Babushka::ArchSystemProfile)
      end
      it "should return RedhatSystemProfile on Red Hat boxes" do
        expect(File).to receive(:exists?).with("/etc/redhat-release").and_return(true)
        expect(subject).to be_an_instance_of(Babushka::RedhatSystemProfile)
      end
      it "should return RedhatSystemProfile on CentOS boxes" do
        expect(File).to receive(:exists?).with("/etc/redhat-release").and_return(true)
        expect(subject).to be_an_instance_of(Babushka::RedhatSystemProfile)
      end
      it "should return FedoraSystemProfile on Fedora boxes" do
        expect(File).to receive(:exists?).with("/etc/fedora-release").and_return(true)
        expect(subject).to be_an_instance_of(Babushka::FedoraSystemProfile)
      end
      it "should return SuseSystemProfile on openSUSE boxes" do
        expect(File).to receive(:exists?).with("/etc/SuSE-release").and_return(true)
        expect(subject).to be_an_instance_of(Babushka::SuseSystemProfile)
      end
      it "should return LinuxSystemProfile on unknown Linux boxes" do
        expect(subject.class).to eq(Babushka::LinuxSystemProfile)
      end
      it "should return a proper description on unknown Linux boxes" do
        expect(subject.description).to eq("Unknown Linux")
      end
      context "version matching" do
        before {
          expect(File).to receive(:exists?).with("/etc/debian_version").and_return(true)
          expect(File).to receive(:exists?).with("/etc/lsb-release").and_return(false)
          expect(subject).to receive(:shell).with("lsb_release -sr").and_return(%Q{7.0})
        }
        it "should detect debian precise" do
          expect(subject.match_list).to eq([:wheezy, :debian, :apt, :linux, :all])
          expect(subject.version).to eq('7.0')
        end
      end
    end
  end
end
