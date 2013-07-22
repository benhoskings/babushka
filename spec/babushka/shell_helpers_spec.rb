require 'spec_helper'

SUCCEEDING_LS = 'ls /bin'
FAILING_LS = 'ls /missing'

describe "shell" do
  it "should return something true on successful commands" do
    ShellHelpers.shell('true').should_not be_nil
  end
  it "should return nil on failed commands" do
    ShellHelpers.shell('false').should be_nil
  end
  it "should return output of successful commands" do
    ShellHelpers.shell('echo lol').should == 'lol'
  end
  it "should accept multiline commands" do
    ShellHelpers.shell("echo babu &&\necho shka").should == "babu\nshka"
  end
  it "should accept environment variables as the first argument" do
    ShellHelpers.shell({'KEY' => 'value'}, "echo $KEY").should == "value"
  end
  it "should provide the shell to supplied blocks when the command succeeds" do
    (the_block = "").should_receive(:was_called)
    ShellHelpers.shell(SUCCEEDING_LS) {|shell|
      the_block.was_called
      shell.stdout.should include('bash')
      shell.stderr.should be_empty
    }
  end
  it "should provide the shell to supplied blocks when the command fails" do
    (the_block = "").should_receive(:was_called)
    ShellHelpers.shell(FAILING_LS) {|shell|
      the_block.was_called
      shell.stdout.should be_empty
      shell.stderr.should include("No such file or directory")
    }
  end
  it "should accept :input parameter" do
    ShellHelpers.shell('cat', :input => 'lol').should == "lol"
  end
  context ":cd parameter" do
    before { (tmp_prefix / 'dir_param').mkdir }
    it "should run in the current directory when :cd isn't specified" do
      ShellHelpers.shell("pwd -P").should == Dir.pwd
    end
    it "should run in the specified directory" do
      ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'dir_param')).should == (tmp_prefix / 'dir_param').to_s
    end
    it "should expand the path" do
      ShellHelpers.shell("pwd", :cd => '~').should == ENV['HOME']
    end
    it "should raise when the path is nonexistent" do
      L{
        ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'missing'))
      }.should raise_error(Errno::ENOENT, "No such file or directory - #{tmp_prefix / 'missing'}")
    end
    it "should raise when the path isn't a directory" do
      L{
        (tmp_prefix / 'notadir').touch
        ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'notadir'))
      }.should raise_error(Errno::ENOTDIR, "Not a directory - #{tmp_prefix / 'notadir'}")
    end
    context "with :create option" do
      it "should run in the specified directory" do
        ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'dir_param'), :create => true).should == (tmp_prefix / 'dir_param').to_s
      end
      it "should create and run when the path is nonexistent" do
        ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'dir_param_with_create'), :create => true).should == (tmp_prefix / 'dir_param_with_create').to_s
      end
    end
  end
end

describe "shell?" do
  it "should return the output for successful commands" do
    ShellHelpers.shell?('echo lol').should == 'lol'
    ShellHelpers.shell?(SUCCEEDING_LS).should be_true
  end
  it "should return false for failed commands" do
    ShellHelpers.shell?('false').should be_false
    ShellHelpers.shell?(FAILING_LS).should be_false
  end
end

describe "shell!" do
  it "should return the output for successful commands" do
    ShellHelpers.shell!('echo lol').should == 'lol'
    ShellHelpers.shell!(SUCCEEDING_LS).should be_true
  end
  it "should return false for failed commands" do
    L{ ShellHelpers.shell!('false') }.should raise_error(Shell::ShellCommandFailed, "Shell command failed: 'false'")
    L{ ShellHelpers.shell!(FAILING_LS) }.should raise_error(Shell::ShellCommandFailed)
  end
end

describe "raw_shell" do
  it "should always return a Shell" do
    ShellHelpers.raw_shell('true').should be_a(Shell)
    ShellHelpers.raw_shell('false').should be_a(Shell)
  end
  it "should return stdout for succeeding commands" do
    shell = ShellHelpers.raw_shell(SUCCEEDING_LS)
    shell.stdout.should include("bash")
    shell.stderr.should be_empty
  end
  it "should return stderr for failed commands" do
    shell = ShellHelpers.raw_shell(FAILING_LS)
    shell.stdout.should be_empty
    shell.stderr.should include("No such file or directory")
  end
  it "should support sudo" do
    ShellHelpers.should_receive(:shell).with('whoami', :sudo => true).once
    ShellHelpers.raw_shell('whoami', :sudo => true)
  end
  it "should handle env vars" do
    ShellHelpers.raw_shell({'KEY' => 'value'}, 'echo $KEY').stdout.should == "value\n"
  end
end

describe 'login_shell' do
  it "should return something true on successful commands" do
    ShellHelpers.login_shell('true').should_not be_nil
  end
  it "should return nil on failed commands" do
    ShellHelpers.login_shell('false').should be_nil
  end
  it "should run as the given user" do
    ShellHelpers.should_receive(:shell_cmd).with('echo $SHELL', {}).and_return('')
    ShellHelpers.should_receive(:shell_cmd).with({}, "sudo -u batman bash -l -c 'whoami'", {}).once
    ShellHelpers.login_shell('whoami', :as => 'batman')
  end
end

describe 'argument behaviour' do
  context "with a single string" do
    it "should support compound commands" do
      ShellHelpers.shell("echo trousers | tr a-z A-Z").should == 'TROUSERS'
    end
    it "should fail with unclosed quotes" do
      ShellHelpers.shell('echo blah"').should be_nil
    end
  end
  context "with an array" do
    it "should treat as a command and args" do
      ShellHelpers.shell(%w[echo trousers | tr a-z A-Z]).should == 'trousers | tr a-z A-Z'
    end
    it "should escape unclosed quotes" do
      ShellHelpers.shell(['echo', 'blah"']).should == 'blah"'
    end
  end
end

describe "sudo" do
  it "should reject array input" do
    L{ ShellHelpers.sudo(%w[whoami]) }.should raise_error(ArgumentError, "#sudo commands have to be passed as a single string, not splatted strings or an array, since the `sudo` is composed from strings.")
  end
  it "should run as root when no user is given" do
    ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u root whoami', {}).once
    ShellHelpers.sudo('whoami')
  end
  it "should run as the given user" do
    ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u batman whoami', {}).once
    ShellHelpers.sudo('whoami', :as => 'batman')
  end
  it "should treat :sudo => 'string' as a username" do
    ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u batman whoami', {}).once
    ShellHelpers.shell('whoami', :sudo => 'batman')
  end
  it "should sudo from #shell when :as is specified" do
    ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u root whoami', {}).once
    ShellHelpers.shell('whoami', :as => 'root')
  end
  context "when already running as the sudo user" do
    it "should not sudo when the user is already root" do
      ShellHelpers.stub(:current_username).and_return('root')
      ShellHelpers.should_receive(:shell_cmd).with({}, 'whoami', {}).once
      ShellHelpers.sudo('whoami')
    end
    it "should not sudo with :as" do
      ShellHelpers.stub(:current_username).and_return('batman')
      ShellHelpers.should_receive(:shell_cmd).with({}, 'whoami', {}).once
      ShellHelpers.sudo('whoami', :as => 'batman')
    end
    it "should not sudo with a :sudo => 'string' username" do
      ShellHelpers.stub(:current_username).and_return('batman')
      ShellHelpers.should_receive(:shell_cmd).with({}, 'whoami', {}).once
      ShellHelpers.shell('whoami', :sudo => 'batman')
    end
    it "should not sudo with a :sudo => Parameter username" do
      ShellHelpers.stub(:current_username).and_return('batman')
      ShellHelpers.should_receive(:shell_cmd).with({}, 'whoami', {}).once
      ShellHelpers.shell('whoami', :sudo => Parameter.new('username').default!('batman'))
    end
    it "should not sudo from #shell when :as is specified" do
      ShellHelpers.stub(:current_username).and_return('root')
      ShellHelpers.should_receive(:shell_cmd).with({}, 'whoami', {}).once
      ShellHelpers.shell('whoami', :as => 'root')
    end
    it "should handle env vars properly" do
      ShellHelpers.stub(:current_username).and_return('root')
      ShellHelpers.should_receive(:shell_cmd).with({'KEY' => 'value'}, 'echo $KEY', {}).once
      ShellHelpers.sudo({'KEY' => 'value'}, 'echo $KEY')
    end
  end
  describe "compound commands" do
    it "should use 'sudo su -' when opts[:su] is supplied" do
      ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo su - root -c "echo \\`whoami\\`"', {}).once
      ShellHelpers.sudo("echo \\`whoami\\`", :su => true)
    end
    it "should use 'sudo su -' for redirects" do
      ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo su - root -c "echo \\`whoami\\` > %s/su_with_redirect"' % tmp_prefix, {}).once
      ShellHelpers.sudo("echo \\`whoami\\` > %s/su_with_redirect" % tmp_prefix)
    end
    it "should use 'sudo su -' for pipes" do
      ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo su - root -c "echo \\`whoami\\` | tee %s/su_with_pipe"' % tmp_prefix, {}).once
      ShellHelpers.sudo("echo \\`whoami\\` | tee %s/su_with_pipe" % tmp_prefix)
    end
  end
end

describe "log_shell" do
  it "should log correctly for a successful command" do
    LogHelpers.should_receive(:log).with("Getting uptime...", {:newline=>false}).once
    ShellHelpers.should_receive(:shell).with('uptime', {:spinner=>true}).and_return("days and days")
    LogHelpers.should_receive(:log).with(" done.", {:as=>nil, :indentation=>false}).once
    ShellHelpers.log_shell 'Getting uptime', 'uptime'
  end
  it "should log correctly for a failing command" do
    LogHelpers.should_receive(:log).with("Setting sail for fail...", {:newline=>false}).once
    ShellHelpers.should_receive(:shell).with('false', {:spinner=>true}).and_return(nil)
    LogHelpers.should_receive(:log).with(" failed", {:as=>:error, :indentation=>false}).once
    ShellHelpers.log_shell 'Setting sail for fail', 'false'
  end
  it "should handle env vars" do
    LogHelpers.should_receive(:log).with("Echoing some vars...", {:newline=>false}).once
    ShellHelpers.should_receive(:shell).with({'KEY' => 'value'}, 'echo $KEY', {:spinner=>true}).and_return('value')
    LogHelpers.should_receive(:log).with(" done.", {:as=>nil, :indentation=>false}).once
    ShellHelpers.log_shell 'Echoing some vars', {'KEY' => 'value'}, 'echo $KEY'
  end
end

describe "which" do
  it "should return a string" do
    ShellHelpers.which('ls').should be_an_instance_of(String)
  end
  it "should return the path for valid commands" do
    path = `which ls`.chomp
    ShellHelpers.which('ls').should == path
  end
  it "should return nil for nonexistent commands" do
    ShellHelpers.which('missing').should be_nil
  end
  it "should handle command parameter passed as Symbol" do
    path = `which ls`.chomp
    ShellHelpers.which(:ls).should == path
  end
end

describe "cmd_dir" do
  it "should return a string" do
    ShellHelpers.cmd_dir('ruby').should be_an_instance_of(String)
  end
  it "should return the cmd_dir of an existing command" do
    ShellHelpers.cmd_dir('ruby').should == `which ruby`.chomp.gsub(/\/ruby$/, '')
  end
  it "should return nil for nonexistent commands" do
    ShellHelpers.cmd_dir('missing').should be_nil
  end
end
