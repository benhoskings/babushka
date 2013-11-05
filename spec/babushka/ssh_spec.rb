require 'spec_helper'

describe Babushka::SSH do
  let(:ssh) {
    Babushka::SSH.new('user@host')
  }
  describe '#shell' do
    it "should run remote commands" do
      Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "ls", :log => true)
      ssh.shell('ls')
    end
  end

  describe '#babushka' do
    before {
      $stdin.stub(:tty?).and_return(false)
    }
    it "should run babushka remotely" do
      Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--git-fs", "--show-args", :log => true).and_return(true)
      ssh.babushka('git')
    end
    it "should raise when the remote babushka fails" do
      Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "fail", "--defaults", "--git-fs", "--show-args", :log => true).and_return(false)
      expect { ssh.babushka('fail') }.to raise_error(Babushka::UnmeetableDep)
    end
    it "should include the args in the commandline" do
      Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--git-fs", "--show-args", "version=1.8.3.2", :log => true).and_return(true)
      ssh.babushka('git', :version => '1.8.3.2')
    end
    it "should handle quotes" do
      dep 'with args', :single, :double
      Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "with args", "--defaults", "--git-fs", "--show-args", "single=a single' quote", "double=\"and a double", :log => true).and_return(true)
      ssh.babushka('with args', :single => "a single' quote", :double => '"and a double')
    end
    context "when running on a terminal" do
      before {
        $stdin.stub(:tty?).and_return(true)
      }
      it "should use colour" do
        Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--git-fs", "--show-args", "--colour", :log => true).and_return(true)
        ssh.babushka('git')
      end
    end
    describe "passing options" do
      before {
        Babushka::Base.task.stub(:opt).and_return(false)
      }
      it "should propagate --update to the remote" do
        Babushka::Base.task.stub(:opt).with(:update).and_return(true)
        Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--git-fs", "--show-args", "--update", "version=1.8.3.2", :log => true).and_return(true)
        ssh.babushka('git', :version => '1.8.3.2')
      end
      it "should propagate --debug to the remote" do
        Babushka::Base.task.stub(:opt).with(:debug).and_return(true)
        Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--git-fs", "--show-args", "--debug", "version=1.8.3.2", :log => true).and_return(true)
        ssh.babushka('git', :version => '1.8.3.2')
      end
    end
  end
end
