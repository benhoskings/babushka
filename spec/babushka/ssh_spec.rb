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
      ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "'babushka' 'git' '--defaults' '--show-args'", :log => true).and_return(true)
      ssh.babushka('git')
    end
    it "should raise when the remote babushka fails" do
      ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "'babushka' 'fail' '--defaults' '--show-args'", :log => true).and_return(false)
      expect { ssh.babushka('fail') }.to raise_error(Babushka::UnmeetableDep)
    end
    it "should include the args in the commandline" do
      ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "'babushka' 'git' '--defaults' '--show-args' 'version=1.8.3.2'", :log => true).and_return(true)
      ssh.babushka('git', :version => '1.8.3.2')
    end
    it "should use colour when running on a terminal" do
      $stdin.stub(:tty?).and_return(true)
      ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "'babushka' 'git' '--defaults' '--show-args' '--colour'", :log => true).and_return(true)
      ssh.babushka('git')
    end
  end
end
