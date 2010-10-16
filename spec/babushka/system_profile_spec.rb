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
