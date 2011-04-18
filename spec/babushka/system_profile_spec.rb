require 'spec_helper'

describe Babushka::SystemProfile, '.for_host' do
  it "should return OSXSystemProfile on Darwin boxes" do
    Babushka::SystemProfile.should_receive(:shell).with("uname -s").and_return("Darwin")
    Babushka::SystemProfile.for_host.should be_an_instance_of(Babushka::OSXSystemProfile)
  end
  it "should return nil on unknown boxes" do
    Babushka::SystemProfile.should_receive(:shell).with("uname -s").and_return("LolOS")
    Babushka::SystemProfile.for_host.should be_nil
  end
  context "on Linux boxes" do
    before {
      Babushka::SystemProfile.should_receive(:shell).with("uname -s").and_return("Linux")
      File.stub!(:exists?).and_return(false)
    }
    it "should return DebianSystemProfile on Debian boxes" do
      File.should_receive(:exists?).with("/etc/debian_version").and_return(true)
      Babushka::AptHelper.stub!(:install!) # so an `lsb_release` install isn't attempted
      Babushka::SystemProfile.for_host.should be_an_instance_of(Babushka::DebianSystemProfile)
    end
    it "should return RedhatSystemProfile on Red Hat boxes" do
      File.should_receive(:exists?).with("/etc/redhat-release").and_return(true)
      Babushka::SystemProfile.for_host.should be_an_instance_of(Babushka::RedhatSystemProfile)
    end
    it "should return LinuxSystemProfile on unknown Linux boxes" do
      Babushka::SystemProfile.for_host.class.should == Babushka::LinuxSystemProfile
    end
    context "version matching" do
      before {
        File.should_receive(:exists?).with("/etc/debian_version").and_return(true)
        @profile = Babushka::SystemProfile.for_host
        @profile.should_receive(:shell).with("which lsb_release").and_return("/usr/bin/lsb_release")
        @profile.should_receive(:shell).with("lsb_release -a").and_return(%Q{
          No LSB modules are available.
          Distributor ID:	Debian
          Description:	Debian GNU/Linux 6.0.1 (squeeze)
          Release:	6.0.1
          Codename:	squeeze
        }.strip)
      }
      it "should detect debian squeeze" do
        @profile.match_list.should == [:squeeze, :debian, :apt, :linux, :all]
        @profile.version.should == '6.0.1'
      end
    end
  end
end

describe Babushka::SystemProfile, "#matches?" do
  # TODO: these specs will only pass on Snow Leopard. It requires refactoring
  # SystemProfile#initialize; no time to do that right now.
  subject { Babushka::SystemProfile.for_host }
  it "should match against only this system" do
    subject.matches?(:osx).should be_true
    subject.matches?(:linux).should be_false
  end
  it "should match against the name" do
    subject.matches?(:snow_leopard).should be_true
    subject.matches?(:leopard).should be_false
  end
  it "should match against the package manager" do
    subject.matches?(:brew).should be_true
    subject.matches?(:apt).should be_false
  end
end
