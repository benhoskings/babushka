require 'spec_helper'

describe Babushka::SystemSpec, '.for_host' do
  it "should return OSXSystemSpec on Darwin boxes" do
    Babushka::SystemSpec.should_receive(:shell).with("uname -s").and_return("Darwin")
    Babushka::SystemSpec.for_host.should be_an_instance_of(Babushka::OSXSystemSpec)
  end
  it "should return nil on unknown boxes" do
    Babushka::SystemSpec.should_receive(:shell).with("uname -s").and_return("LolOS")
    Babushka::SystemSpec.for_host.should be_nil
  end
  context "on Linux boxes" do
    before {
      Babushka::SystemSpec.should_receive(:shell).with("uname -s").and_return("Linux")
      File.stub!(:exists?).and_return(false)
    }
    it "should return DebianSystemSpec on Debian boxes" do
      File.should_receive(:exists?).with("/etc/debian_version").and_return(true)
      Babushka::SystemSpec.for_host.should be_an_instance_of(Babushka::DebianSystemSpec)
    end
    it "should return RedhatSystemSpec on Red Hat boxes" do
      File.should_receive(:exists?).with("/etc/redhat-release").and_return(true)
      File.should_receive(:read).with("/etc/redhat-release").and_return("Fedora release 13 (Goddard)\n")
      Babushka::SystemSpec.for_host.should be_an_instance_of(Babushka::RedhatSystemSpec)
    end
    it "should return nil on unknown Linux boxes" do
      Babushka::SystemSpec.for_host.should be_nil
    end
  end
  
end
