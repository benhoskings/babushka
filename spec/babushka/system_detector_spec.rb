require 'spec_helper'

describe Babushka::SystemDetector do
  subject {
    Babushka::SystemDetector.profile_for_host
  }

  describe '.for_host' do
    it "should return OSXSystemProfile on Darwin boxes" do
      ShellHelpers.should_receive(:shell).with("uname -s").and_return("Darwin")
      subject.should be_an_instance_of(Babushka::OSXSystemProfile)
    end
    it "should return UnknownSystem on unknown boxes" do
      ShellHelpers.should_receive(:shell).with("uname -s").and_return("LolOS")
      subject.should be_an_instance_of(Babushka::UnknownSystem)
    end
    context "on BSD boxes" do
      it "should return DragonFlySystemProfile on Dragonfly boxes" do
        ShellHelpers.should_receive(:shell).with("uname -s").and_return("DragonFly")
        subject.should be_an_instance_of(Babushka::DragonFlySystemProfile)
      end
      it "should return FreeBSDSystemProfile on FreeBSD boxes" do
        ShellHelpers.should_receive(:shell).with("uname -s").and_return("FreeBSD")
        subject.should be_an_instance_of(Babushka::FreeBSDSystemProfile)
      end
    end
    context "on Linux boxes" do
      before {
        ShellHelpers.should_receive(:shell).with("uname -s").and_return("Linux")
        File.stub!(:exists?).and_return(false)
      }
      it "should return DebianSystemProfile on Debian boxes" do
        File.should_receive(:exists?).with("/etc/debian_version").and_return(true)
        File.should_receive(:exists?).with("/etc/lsb-release").and_return(false)
        subject.should be_an_instance_of(Babushka::DebianSystemProfile)
      end
      it "should return UbuntuSystemProfile on Ubuntu boxes" do
        File.should_receive(:exists?).with("/etc/debian_version").and_return(true)
        File.should_receive(:exists?).with("/etc/lsb-release").and_return(true)
        File.should_receive(:read).with("/etc/lsb-release").and_return('Ubuntu')
        subject.should be_an_instance_of(Babushka::UbuntuSystemProfile)
      end
      it "should return ArchSystemProfile on Arch boxes" do
        File.should_receive(:exists?).with("/etc/arch-release").and_return(true)
        subject.should be_an_instance_of(Babushka::ArchSystemProfile)
      end
      it "should return RedhatSystemProfile on Red Hat boxes" do
        File.should_receive(:exists?).with("/etc/redhat-release").and_return(true)
        subject.should be_an_instance_of(Babushka::RedhatSystemProfile)
      end
      it "should return RedhatSystemProfile on CentOS boxes" do
        File.should_receive(:exists?).with("/etc/redhat-release").and_return(true)
        subject.should be_an_instance_of(Babushka::RedhatSystemProfile)
      end
      it "should return FedoraSystemProfile on Fedora boxes" do
        File.should_receive(:exists?).with("/etc/fedora-release").and_return(true)
        subject.should be_an_instance_of(Babushka::FedoraSystemProfile)
      end
      it "should return LinuxSystemProfile on unknown Linux boxes" do
        subject.class.should == Babushka::LinuxSystemProfile
      end
      it "should return a proper description on unknown Linux boxes" do
        subject.description.should == "Unknown Linux"
      end
      context "version matching" do
        before {
          File.should_receive(:exists?).with("/etc/debian_version").and_return(true)
          File.should_receive(:exists?).with("/etc/lsb-release").and_return(false)
          File.should_receive(:read).with("/etc/os-release").and_return(%Q{PRETTY_NAME="Debian GNU/Linux 7.0 (wheezy)"\nNAME="Debian GNU/Linux"\nVERSION_ID="7.0"\nVERSION="7.0 (wheezy)"\nID=debian\nANSI_COLOR="1;31"\nHOME_URL="http://www.debian.org/"\nSUPPORT_URL="http://www.debian.org/support/"\nBUG_REPORT_URL="http://bugs.debian.org/""})
        }
        it "should detect debian precise" do
          subject.match_list.should == [:wheezy, :debian, :apt, :linux, :all]
          subject.version.should == '7.0'
        end
      end
    end
  end
end
