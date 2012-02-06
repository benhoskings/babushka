require 'spec_helper'

SucceedingLs = 'ls /bin'
FailingLs = 'ls /missing'

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
  it "should accept environment variables as the first argument" do
    shell({'KEY' => 'value'}, "echo $KEY").should == "value"
  end
  it "should provide the shell to supplied blocks when the command succeeds" do
    (the_block = "").should_receive(:was_called)
    shell(SucceedingLs) {|shell|
      the_block.was_called
      shell.stdout.should include('bash')
      shell.stderr.should be_empty
    }
  end
  it "should provide the shell to supplied blocks when the command fails" do
    (the_block = "").should_receive(:was_called)
    shell(FailingLs) {|shell|
      the_block.was_called
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
      shell("pwd -P").should == Dir.pwd
    end
    it "should run in the specified directory" do
      shell("pwd", :cd => (tmp_prefix / 'dir_param')).should == (tmp_prefix / 'dir_param').to_s
    end
    it "should expand the path" do
      shell("pwd", :cd => '~').should == ENV['HOME']
    end
    it "should raise when the path is nonexistent" do
      L{
        shell("pwd", :cd => (tmp_prefix / 'missing'))
      }.should raise_error(Errno::ENOENT, "No such file or directory - #{tmp_prefix / 'missing'}")
    end
    it "should raise when the path isn't a directory" do
      L{
        (tmp_prefix / 'notadir').touch
        shell("pwd", :cd => (tmp_prefix / 'notadir'))
      }.should raise_error(Errno::ENOTDIR, "Not a directory - #{tmp_prefix / 'notadir'}")
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
  it "should return the output for successful commands" do
    shell?('echo lol').should == 'lol'
    shell?(SucceedingLs).should be_true
  end
  it "should return false for failed commands" do
    shell?('false').should be_false
    shell?(FailingLs).should be_false
  end
end

describe "shell!" do
  it "should return the output for successful commands" do
    shell!('echo lol').should == 'lol'
    shell!(SucceedingLs).should be_true
  end
  it "should return false for failed commands" do
    L{ shell!('false') }.should raise_error(Shell::ShellCommandFailed, "Shell command failed: 'false'")
    L{ shell!(FailingLs) }.should raise_error(Shell::ShellCommandFailed)
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
  it "should handle env vars" do
    raw_shell({'KEY' => 'value'}, 'echo $KEY').stdout.should == "value\n"
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
  it "should reject array input" do
    L{ sudo(%w[whoami]) }.should raise_error(ArgumentError, "#sudo commands have to be passed as a single string, not splatted strings or an array, since the `sudo` is composed from strings.")
  end
  it "should run as root when no user is given" do
    should_receive(:shell_cmd).with({}, 'sudo -u root whoami', {}).once
    sudo('whoami')
  end
  it "should run as the given user" do
    should_receive(:shell_cmd).with({}, 'sudo -u batman whoami', {}).once
    sudo('whoami', :as => 'batman')
  end
  it "should treat :sudo => 'string' as a username" do
    should_receive(:shell_cmd).with({}, 'sudo -u batman whoami', {}).once
    shell('whoami', :sudo => 'batman')
  end
  it "should sudo from #shell when :as is specified" do
    should_receive(:shell_cmd).with({}, 'sudo -u root whoami', {}).once
    shell('whoami', :as => 'root')
  end
  context "when already running as the sudo user" do
    it "should not sudo when the user is already root" do
      stub!(:current_username).and_return('root')
      should_receive(:shell_cmd).with({}, 'whoami', {}).once
      sudo('whoami')
    end
    it "should not sudo with :as" do
      stub!(:current_username).and_return('batman')
      should_receive(:shell_cmd).with({}, 'whoami', {}).once
      sudo('whoami', :as => 'batman')
    end
    it "should not sudo with a :sudo => 'string' username" do
      stub!(:current_username).and_return('batman')
      should_receive(:shell_cmd).with({}, 'whoami', {}).once
      shell('whoami', :sudo => 'batman')
    end
    it "should not sudo with a :sudo => Parameter username" do
      stub!(:current_username).and_return('batman')
      should_receive(:shell_cmd).with({}, 'whoami', {}).once
      shell('whoami', :sudo => Parameter.new('username').default!('batman'))
    end
    it "should not sudo from #shell when :as is specified" do
      stub!(:current_username).and_return('root')
      should_receive(:shell_cmd).with({}, 'whoami', {}).once
      shell('whoami', :as => 'root')
    end
    it "should handle env vars properly" do
      stub!(:current_username).and_return('root')
      should_receive(:shell_cmd).with({'KEY' => 'value'}, 'echo $KEY', {}).once
      sudo({'KEY' => 'value'}, 'echo $KEY')
    end
  end
  describe "compound commands" do
    it "should use 'sudo su -' when opts[:su] is supplied" do
      should_receive(:shell_cmd).with({}, 'sudo su - root -c "echo \\`whoami\\`"', {}).once
      sudo("echo \\`whoami\\`", :su => true)
    end
    it "should use 'sudo su -' for redirects" do
      should_receive(:shell_cmd).with({}, 'sudo su - root -c "echo \\`whoami\\` > %s/su_with_redirect"' % tmp_prefix, {}).once
      sudo("echo \\`whoami\\` > %s/su_with_redirect" % tmp_prefix)
    end
    it "should use 'sudo su -' for pipes" do
      should_receive(:shell_cmd).with({}, 'sudo su - root -c "echo \\`whoami\\` | tee %s/su_with_pipe"' % tmp_prefix, {}).once
      sudo("echo \\`whoami\\` | tee %s/su_with_pipe" % tmp_prefix)
    end
  end
end

describe "log_shell" do
  it "should log correctly for a successful command" do
    should_receive(:log).with("Getting uptime...", {:newline=>false}).once
    should_receive(:shell).with('uptime', {:spinner=>true}).and_return("days and days")
    should_receive(:log).with(" done.", {:as=>nil, :indentation=>false}).once
    log_shell 'Getting uptime', 'uptime'
  end
  it "should log correctly for a failing command" do
    should_receive(:log).with("Setting sail for fail...", {:newline=>false}).once
    should_receive(:shell).with('false', {:spinner=>true}).and_return(nil)
    should_receive(:log).with(" failed", {:as=>:error, :indentation=>false}).once
    log_shell 'Setting sail for fail', 'false'
  end
  it "should handle env vars" do
    should_receive(:log).with("Echoing some vars...", {:newline=>false}).once
    should_receive(:shell).with({'KEY' => 'value'}, 'echo $KEY', {:spinner=>true}).and_return('value')
    should_receive(:log).with(" done.", {:as=>nil, :indentation=>false}).once
    log_shell 'Echoing some vars', {'KEY' => 'value'}, 'echo $KEY'
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
    which('missing').should be_nil
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
    cmd_dir('missing').should be_nil
  end
end
