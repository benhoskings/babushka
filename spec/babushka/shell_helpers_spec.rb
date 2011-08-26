require 'spec_helper'

SucceedingLs = 'ls /bin'
FailingLs = 'ls /nonexistent'

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
  it "should accept multiline commands" do
    shell("echo babu &&\necho shka").should == "babu\nshka"
  end
  it "should provide the shell to supplied blocks" do
    shell(SucceedingLs) {|shell|
      shell.stdout.should include('bash')
      shell.stderr.should be_empty
    }
    shell(FailingLs) {|shell|
      shell.stdout.should be_empty
      shell.stderr.should include("No such file or directory")
    }
  end
  it "should accept :input parameter" do
    shell('cat', :input => 'lol').should == "lol"
  end
  context ":cd parameter" do
    before { (tmp_prefix / 'dir_param').mkdir }
    it "should run in the current directory when :cd isn't specified" do
      shell("pwd").should == Dir.pwd
    end
    it "should run in the specified directory" do
      shell("pwd", :cd => (tmp_prefix / 'dir_param')).should == (tmp_prefix / 'dir_param').to_s
    end
    it "should expand the path" do
      shell("pwd", :cd => '~').should == ENV['HOME']
    end
    it "should raise when the path is nonexistent" do
      L{
        shell("pwd", :cd => (tmp_prefix / 'nonexistent'))
      }.should raise_error(Errno::ENOENT, "No such file or directory - #{tmp_prefix / 'nonexistent'}")
    end
    context "with :create option" do
      it "should run in the specified directory" do
        shell("pwd", :cd => (tmp_prefix / 'dir_param'), :create => true).should == (tmp_prefix / 'dir_param').to_s
      end
      it "should create and run when the path is nonexistent" do
        shell("pwd", :cd => (tmp_prefix / 'dir_param_with_create'), :create => true).should == (tmp_prefix / 'dir_param_with_create').to_s
      end
    end
  end
end

describe "shell?" do
  it "should return true for successful commands" do
    shell?('true').should be_true
    shell?(SucceedingLs).should be_true
  end
  it "should return false for failed commands" do
    shell?('false').should be_false
    shell?(FailingLs).should be_false
  end
end

describe "raw_shell" do
  it "should always return a Shell" do
    raw_shell('true').should be_a(Shell)
    raw_shell('false').should be_a(Shell)
  end
  it "should return stdout for succeeding commands" do
    shell = raw_shell(SucceedingLs)
    shell.stdout.should include("bash")
    shell.stderr.should be_empty
  end
  it "should return stderr for failed commands" do
    shell = raw_shell(FailingLs)
    shell.stdout.should be_empty
    shell.stderr.should include("No such file or directory")
  end
  it "should support sudo" do
    should_receive(:shell).with('whoami', :sudo => true).once
    raw_shell('whoami', :sudo => true)
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
  it "should run as root when no user is given" do
    should_receive(:shell_cmd).with('sudo -u root whoami', {}).once
    sudo('whoami')
  end
  it "should run as the given user" do
    should_receive(:shell_cmd).with('sudo -u ben whoami', {}).once
    sudo('whoami', :as => ENV['USER'])
  end
  it "should treat :sudo => 'string' as a username" do
    should_receive(:shell_cmd).with('sudo -u ben whoami', {}).once
    shell('whoami', :sudo => ENV['USER'])
  end
  it "should sudo from #shell when :as is specified" do
    should_receive(:shell_cmd).with('sudo -u root whoami', {}).once
    shell('whoami', :as => 'root')
  end
  describe "compound commands" do
    it "should use 'sudo su -' when opts[:su] is supplied" do
      should_receive(:shell_cmd).with('sudo su - root -c "echo \\`whoami\\`"', {}).once
      sudo("echo \\`whoami\\`", :su => true)
    end
    it "should use 'sudo su -' for redirects" do
      should_receive(:shell_cmd).with('sudo su - root -c "echo \\`whoami\\` > %s/su_with_redirect"' % tmp_prefix, {}).once
      sudo("echo \\`whoami\\` > %s/su_with_redirect" % tmp_prefix)
    end
    it "should use 'sudo su -' for pipes" do
      should_receive(:shell_cmd).with('sudo su - root -c "echo \\`whoami\\` | tee %s/su_with_pipe"' % tmp_prefix, {}).once
      sudo("echo \\`whoami\\` | tee %s/su_with_pipe" % tmp_prefix)
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
  it "should return a string" do
    which('ls').should be_an_instance_of(String)
  end
  it "should return the path for valid commands" do
    path = `which ls`.chomp
    which('ls').should == path
  end
  it "should return nil for nonexistent commands" do
    which('nonexistent').should be_nil
  end
  it "should handle command parameter passed as Symbol" do
    path = `which ls`.chomp
    which(:ls).should == path
  end
end

describe "cmd_dir" do
  it "should return a string" do
    cmd_dir('ruby').should be_an_instance_of(String)
  end
  it "should return the cmd_dir of an existing command" do
    cmd_dir('ruby').should == `which ruby`.chomp.gsub(/\/ruby$/, '')
  end
  it "should return nil for nonexistent commands" do
    cmd_dir('nonexistent').should be_nil
  end
end
