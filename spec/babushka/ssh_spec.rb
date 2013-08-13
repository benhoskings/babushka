require 'spec_helper'

describe Babushka::SSH do
  let(:ssh) {
    Babushka::SSH.new('user@host')
  }
  describe '#shell' do
    it "should run remote commands" do
      ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "'ls'", :log => true)
      ssh.shell('ls')
    end
  end

  describe '#babushka' do
    it "should run babushka remotely" do
      ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "'babushka' 'git'", :log => true).and_return(true)
      ssh.babushka('git')
    end
    it "should raise when the remote babushka fails" do
      ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "'babushka' 'fail'", :log => true).and_return(false)
      expect { ssh.babushka('fail') }.to raise_error(Babushka::UnmeetableDep)
    end
  end
end
