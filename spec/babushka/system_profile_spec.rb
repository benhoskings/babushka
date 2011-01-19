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
      File.should_receive(:read).with("/etc/redhat-release").and_return("Fedora release 13 (Goddard)\n")
      Babushka::SystemProfile.for_host.should be_an_instance_of(Babushka::RedhatSystemProfile)
    end
    it "should return nil on unknown Linux boxes" do
      Babushka::SystemProfile.for_host.should be_nil
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
