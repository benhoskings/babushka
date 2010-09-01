require 'spec_helper'

SucceedingLs = 'ls /bin'
FailingLs = 'ls /nonexistent'

class ShellTester; extend ShellHelpers end

describe "shell" do
  it "should return something true on successful commands" do
    shell('true').should_not be_nil
  end
  it "should return nil on failed commands" do
    shell('false').should be_nil
  end
  it "should return output of successful commands" do
    shell('echo lol').should == 'lol'
  end
  it "should provide the shell to supplied blocks" do
    shell(SucceedingLs) {|shell|
      shell.stdout.should include 'bash'
      shell.stderr.should be_empty
    }
    shell(FailingLs) {|shell|
      shell.stdout.should be_empty
      shell.stderr.should include "No such file or directory"
    }
  end
  it "should accept :input parameter" do
    shell('cat', :input => 'lol').should == "lol"
  end
end

describe "failable_shell" do
  it "should always return a Shell" do
    failable_shell('true').should be_a Shell
    failable_shell('false').should be_a Shell
  end
  it "should return stderr for failed commands" do
    shell = failable_shell(FailingLs)
    shell.stdout.should be_empty
    shell.stderr.should include "No such file or directory"
  end
end

describe 'argument behaviour' do
  context "with a single string" do
    it "should support compound commands" do
      shell("echo trousers | tr a-z A-Z").should == 'TROUSERS'
    end
    it "should fail with unclosed quotes" do
      shell('echo blah"').should be_nil
    end
  end
  context "with an array" do
    it "should treat as a command and args" do
      shell(%w[echo trousers | tr a-z A-Z]).should == 'trousers | tr a-z A-Z'
    end
    it "should escape unclosed quotes" do
      shell(['echo', 'blah"']).should == 'blah"'
    end
  end
end

describe "sudo" do
  before {
    @current_user = `whoami`.chomp
  }
  it "should run as root when no user is given" do
    sudo('whoami').should == 'root'
  end
  it "should run as the given user" do
    sudo('whoami', :as => @current_user).should == @current_user
  end
  describe "compound commands" do
    it "should use 'sudo su -' when opts[:su] is supplied" do
      sudo("echo \\`whoami\\`", :su => true).should == 'root'
    end
    describe "redirects" do
      before {
        @tmp_path = tmp_prefix / 'su_with_redirect'
        sudo "rm #{@tmp_path}"
      }
      it "should use 'sudo su -'" do
        sudo("echo \\`whoami\\` > #{@tmp_path}")
        @tmp_path.read.chomp.should == 'root'
        @tmp_path.owner.should == 'root'
      end
    end
    describe "pipes" do
      before {
        @tmp_path = tmp_prefix / 'su_with_redirect'
        sudo "rm #{@tmp_path}"
      }
      it "should use 'sudo su -'" do
        sudo("echo \\`whoami\\` | tee #{@tmp_path}")
        @tmp_path.read.chomp.should == 'root'
        @tmp_path.owner.should == 'root'
      end
    end
  end
end

describe "log_shell" do
  before {
    should_receive(:log).exactly(2).times
  }
  it "should log and run a command" do
    should_receive(:shell).with('uptime', {:spinner => true})
    log_shell 'Getting uptime', 'uptime'
  end
  it "should log correctly for a failing command" do
    should_receive(:shell).with('nonexistent', {:spinner => true})
    log_shell 'Nonexistent shell command', 'nonexistent'
  end
end

describe "which" do
  it "should return the path for valid commands" do
    path = `which ls`.chomp
    ShellTester.which('ls').should == path
  end
  it "should return nil for nonexistent commands" do
    ShellTester.which('nonexistent').should be_nil
  end
end

describe "cmd_dir" do
  it "should return the cmd_dir of an existing command" do
    ShellTester.cmd_dir('ruby').should == `which ruby`.chomp.gsub(/\/ruby$/, '')
  end
  it "should return nil for nonexistent commands" do
    ShellTester.cmd_dir('nonexistent').should be_nil
  end
end
