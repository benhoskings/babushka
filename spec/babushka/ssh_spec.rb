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

  describe '#log_shell' do
    it "should log about the command being run, and run it" do
      # This is messy; refactoring Loghelpers.log will fix it.
      Babushka::LogHelpers.stub(:log)
      Babushka::LogHelpers.should_receive(:log).with('user@host $ ls', :closing_status => 'user@host $ ls').and_call_original
      ssh.should_receive(:shell).with('ls') { true }
      ssh.log_shell('ls')
    end
    it "should truncate long args" do
      cmd_message = "user@host $ ls lorem_ipsum_dolor_sit_amet_consectetur_a…"
      Babushka::LogHelpers.should_receive(:log).with(cmd_message, :closing_status => cmd_message)
      ssh.log_shell('ls', 'lorem_ipsum_dolor_sit_amet_consectetur_adipisicing_elit_sed_do_eiusmod')
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
    it "should include dep args in the commandline" do
      Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--git-fs", "--show-args", "version=1.8.3.2", :log => true).and_return(true)
      ssh.babushka('git', :version => '1.8.3.2')
    end
    it "should sort the dep args" do
      Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--git-fs", "--show-args", "a=a", "b=b", "c=c", "d=d", :log => true).and_return(true)
      ssh.babushka('git', :b => 'b', :d => 'd', :c => 'c', :a => 'a')
    end
    it "should escape the dep name" do
      Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "git\\ aliases", "--defaults", "--git-fs", "--show-args", "version=1.8.3.2", :log => true).and_return(true)
      ssh.babushka('git aliases', :version => '1.8.3.2')
    end
    it "should escape the args" do
      Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--git-fs", "--show-args", "version=this\\ needs'\n'escaping", :log => true).and_return(true)
      ssh.babushka('git', :version => "this needs\nescaping")
    end
    it "should escape quotes" do
      Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "quotes", "--defaults", "--git-fs", "--show-args", "double=\\\"doublequote", "single=single\\'quote", :log => true).and_return(true)
      ssh.babushka('quotes', :single => "single'quote", :double => '"doublequote')
    end
    it "should escape everything as required" do
      Babushka::ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "babushka", "escaping", "--defaults", "--git-fs", "--show-args", "arg=a\\ gnarly\\ string\\ \\|\\ with\\ \\'many'\n'tricks\\\"", :log => true).and_return(true)
      ssh.babushka('escaping', :arg => "a gnarly string | with 'many\ntricks\"")
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
