# coding: utf-8

require 'spec_helper'

describe Babushka::SSH do
  let(:ssh) {
    Babushka::SSH.new('user@host')
  }

  describe '#shell' do
    it "should run remote commands" do
      expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "ls", :log => true)
      ssh.shell('ls')
    end
  end

  describe '#log_shell' do
    before {
      allow(Babushka::ANSI).to receive(:using_colour?) { false }
    }
    it "should log about the command being run, and run it" do
      # This is messy; refactoring Loghelpers.log will fix it.
      allow(Babushka::LogHelpers).to receive(:log)
      expect(Babushka::LogHelpers).to receive(:log).with('user@host $ ls', :closing_status => 'user@host $ ls').and_call_original
      expect(ssh).to receive(:shell).with('ls') { true }
      ssh.log_shell('ls')
    end
    it "should truncate long args" do
      cmd_message = "user@host $ ls lorem_ipsum_dolor_sit_amet_consectetur_a…"
      expect(Babushka::LogHelpers).to receive(:log).with(cmd_message, :closing_status => cmd_message)
      ssh.log_shell('ls', 'lorem_ipsum_dolor_sit_amet_consectetur_adipisicing_elit_sed_do_eiusmod')
    end
  end

  describe '#babushka' do
    it "should run babushka remotely" do
      expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--show-args", :log => true).and_return(true)
      ssh.babushka('git')
    end
    it "should log the command via log_shell" do
      expect(ssh).to receive(:log_shell).with("babushka", "git", "--defaults", "--show-args").and_return(true)
      ssh.babushka('git')
    end
    it "should raise when the remote babushka fails" do
      expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "fail", "--defaults", "--show-args", :log => true).and_return(false)
      expect { ssh.babushka('fail') }.to raise_error(Babushka::UnmeetableDep)
    end
    it "should include dep args in the commandline" do
      expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--show-args", "version=1.8.3.2", :log => true).and_return(true)
      ssh.babushka('git', :version => '1.8.3.2')
    end
    it "should sort the dep args" do
      expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--show-args", "a=a", "b=b", "c=c", "d=d", :log => true).and_return(true)
      ssh.babushka('git', :b => 'b', :d => 'd', :c => 'c', :a => 'a')
    end
    it "should escape the dep name" do
      expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "git\\ aliases", "--defaults", "--show-args", "version=1.8.3.2", :log => true).and_return(true)
      ssh.babushka('git aliases', :version => '1.8.3.2')
    end
    it "should escape the args" do
      expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--show-args", "version=this\\ needs'\n'escaping", :log => true).and_return(true)
      ssh.babushka('git', :version => "this needs\nescaping")
    end
    it "should convert the args to strings for ruby < 2.0" do
      expect(Shellwords).to receive(:escape).with("git").and_call_original
      expect(Shellwords).to receive(:escape).with("1.23").and_call_original
      expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--show-args", "version=1.23", :log => true).and_return(true)
      ssh.babushka('git', :version => 1.23)
    end
    it "should escape quotes" do
      expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "quotes", "--defaults", "--show-args", "double=\\\"doublequote", "single=single\\'quote", :log => true).and_return(true)
      ssh.babushka('quotes', :single => "single'quote", :double => '"doublequote')
    end
    it "should escape everything as required" do
      expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "escaping", "--defaults", "--show-args", "arg=a\\ gnarly\\ string\\ \\|\\ with\\ \\'many'\n'tricks\\\"", :log => true).and_return(true)
      ssh.babushka('escaping', :arg => "a gnarly string | with 'many\ntricks\"")
    end
    describe "passing options" do
      before {
        allow(Babushka::Base.task).to receive(:opt).and_return(false)
      }
      it "should send --git-fs to the remote when --remote-git-fs is used" do
        allow(Babushka::Base.task).to receive(:opt).with(:remote_git_fs).and_return(true)
        expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--show-args", "--git-fs", "version=1.8.3.2", :log => true).and_return(true)
        ssh.babushka('git', :version => '1.8.3.2')
      end
      it "should propagate --colour to the remote" do
        allow(Babushka::Base.task).to receive(:opt).with(:"[no_]color").and_return(true)
        expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--show-args", "--colour", "version=1.8.3.2", :log => true).and_return(true)
        ssh.babushka('git', :version => '1.8.3.2')
      end
      it "should propagate --update to the remote" do
        allow(Babushka::Base.task).to receive(:opt).with(:update).and_return(true)
        expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--show-args", "--update", "version=1.8.3.2", :log => true).and_return(true)
        ssh.babushka('git', :version => '1.8.3.2')
      end
      it "should propagate --debug to the remote" do
        allow(Babushka::Base.task).to receive(:opt).with(:debug).and_return(true)
        expect(Babushka::ShellHelpers).to receive(:shell).with("ssh", "-A", "user@host", "babushka", "git", "--defaults", "--show-args", "--debug", "version=1.8.3.2", :log => true).and_return(true)
        ssh.babushka('git', :version => '1.8.3.2')
      end
    end
  end
end
