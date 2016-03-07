require 'spec_helper'
require 'tmpdir'

SUCCEEDING_LS = 'ls /bin'
FAILING_LS = 'ls /missing'

describe "shell" do
  it "should return something true on successful commands" do
    Babushka::ShellHelpers.shell('true').should_not be_nil
  end
  it "should return nil on failed commands" do
    Babushka::ShellHelpers.shell('false').should be_nil
  end
  it "should return output of successful commands" do
    Babushka::ShellHelpers.shell('echo lol').should == 'lol'
  end
  it "should accept multiline commands" do
    Babushka::ShellHelpers.shell("echo babu &&\necho shka").should == "babu\nshka"
  end
  it "should accept environment variables as the first argument" do
    Babushka::ShellHelpers.shell({'KEY' => 'value'}, "echo $KEY").should == "value"
  end
  it "should provide the shell to supplied blocks when the command succeeds" do
    (the_block = "").should_receive(:was_called)
    Babushka::ShellHelpers.shell(SUCCEEDING_LS) {|shell|
      the_block.was_called
      shell.stdout.should include('bash')
      shell.stderr.should be_empty
    }
  end
  it "should provide the shell to supplied blocks when the command fails" do
    (the_block = "").should_receive(:was_called)
    Babushka::ShellHelpers.shell(FAILING_LS) {|shell|
      the_block.was_called
      shell.stdout.should be_empty
      shell.stderr.should include("No such file or directory")
    }
  end
  it "should accept :input parameter" do
    Babushka::ShellHelpers.shell('cat', :input => 'lol').should == "lol"
  end
  context ":cd parameter" do
    before { (tmp_prefix / 'dir_param').mkdir }
    it "should run in the current directory when :cd isn't specified" do
      Babushka::ShellHelpers.shell("pwd -P").should == Dir.pwd
    end
    it "should run in the specified directory" do
      Babushka::ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'dir_param')).should == (tmp_prefix / 'dir_param').to_s
    end
    it "should expand the path" do
      Babushka::ShellHelpers.shell("pwd", :cd => '~').should == ENV['HOME']
    end
    it "should raise when the path is nonexistent" do
      L{
        Babushka::ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'missing'))
      }.should raise_error(Errno::ENOENT, "No such file or directory - #{tmp_prefix / 'missing'}")
    end
    it "should raise when the path isn't a directory" do
      L{
        (tmp_prefix / 'notadir').touch
        Babushka::ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'notadir'))
      }.should raise_error(Errno::ENOTDIR, "Not a directory - #{tmp_prefix / 'notadir'}")
    end
    context "with :create option" do
      it "should run in the specified directory" do
        Babushka::ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'dir_param'), :create => true).should == (tmp_prefix / 'dir_param').to_s
      end
      it "should create and run when the path is nonexistent" do
        Babushka::ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'dir_param_with_create'), :create => true).should == (tmp_prefix / 'dir_param_with_create').to_s
      end
    end
  end
end

describe "shell?" do
  it "should return the output for successful commands" do
    Babushka::ShellHelpers.shell?('echo lol').should == 'lol'
    Babushka::ShellHelpers.shell?(SUCCEEDING_LS).should be_truthy
  end
  it "should return false for failed commands" do
    Babushka::ShellHelpers.shell?('false').should be_falsey
    Babushka::ShellHelpers.shell?(FAILING_LS).should be_falsey
  end
end

describe "shell!" do
  it "should return the output for successful commands" do
    Babushka::ShellHelpers.shell!('echo lol').should == 'lol'
    Babushka::ShellHelpers.shell!(SUCCEEDING_LS).should be_truthy
  end
  it "should return false for failed commands" do
    L{ Babushka::ShellHelpers.shell!('false') }.should raise_error(Babushka::Shell::ShellCommandFailed, "Shell command failed: 'false'")
    L{ Babushka::ShellHelpers.shell!(FAILING_LS) }.should raise_error(Babushka::Shell::ShellCommandFailed)
  end
end

describe "raw_shell" do
  it "should always return a Shell" do
    Babushka::ShellHelpers.raw_shell('true').should be_a(Babushka::Shell)
    Babushka::ShellHelpers.raw_shell('false').should be_a(Babushka::Shell)
  end
  it "should return stdout for succeeding commands" do
    shell = Babushka::ShellHelpers.raw_shell(SUCCEEDING_LS)
    shell.stdout.should include("bash")
    shell.stderr.should be_empty
  end
  it "should return stderr for failed commands" do
    shell = Babushka::ShellHelpers.raw_shell(FAILING_LS)
    shell.stdout.should be_empty
    shell.stderr.should include("No such file or directory")
  end
  it "should support sudo" do
    Babushka::ShellHelpers.should_receive(:shell).with('whoami', :sudo => true).once
    Babushka::ShellHelpers.raw_shell('whoami', :sudo => true)
  end
  it "should handle env vars" do
    Babushka::ShellHelpers.raw_shell({'KEY' => 'value'}, 'echo $KEY').stdout.should == "value\n"
  end
end

describe 'login_shell' do
  it "should return something true on successful commands" do
    Babushka::ShellHelpers.login_shell('true').should_not be_nil
  end
  it "should return nil on failed commands" do
    Babushka::ShellHelpers.login_shell('false').should be_nil
  end
  it "should run as the given user" do
    Babushka::ShellHelpers.should_receive(:shell_cmd).with('echo $SHELL', {}).and_return('')
    Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, "sudo -u batman bash -l -c 'whoami'", {}).once
    Babushka::ShellHelpers.login_shell('whoami', :as => 'batman')
  end
end

describe 'argument behaviour' do
  context "with a single string" do
    it "should support compound commands" do
      Babushka::ShellHelpers.shell("echo trousers | tr a-z A-Z").should == 'TROUSERS'
    end
    it "should fail with unclosed quotes" do
      Babushka::ShellHelpers.shell('echo blah"').should be_nil
    end
  end
  context "with an array" do
    it "should treat as a command and args" do
      Babushka::ShellHelpers.shell(%w[echo trousers | tr a-z A-Z]).should == 'trousers | tr a-z A-Z'
    end
    it "should escape unclosed quotes" do
      Babushka::ShellHelpers.shell(['echo', 'blah"']).should == 'blah"'
    end
  end
end

describe "sudo" do
  it "should accept string input" do
    Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u root whoami', {}).once
    Babushka::ShellHelpers.sudo('whoami')
  end
  it "should accept splatted input" do
    Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u root echo test', {}).once
    Babushka::ShellHelpers.sudo('echo', 'test')
  end
  it "should accept array input" do
    Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u root whoami', {}).once
    Babushka::ShellHelpers.sudo(['whoami'])
  end
  describe 'command joining' do
    it "should escape & join splatted args" do
      Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u root echo test with\ a\ \"quote', {}).once
      Babushka::ShellHelpers.sudo('echo', 'test', 'with a "quote')
    end
    it "should escape & join array args" do
      Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u root echo test with\ a\ \"quote', {}).once
      Babushka::ShellHelpers.sudo(['echo', 'test', 'with a "quote'])
    end
    it "should not escape string args" do
      Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u root echo test with a \"quote', {}).once
      Babushka::ShellHelpers.sudo('echo test with a \"quote')
    end
  end
  it "should run as root when no user is given" do
    Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u root whoami', {}).once
    Babushka::ShellHelpers.sudo('whoami')
  end
  it "should run as the given user" do
    Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u batman whoami', {}).once
    Babushka::ShellHelpers.sudo('whoami', :as => 'batman')
  end
  it "should treat :sudo => 'string' as a username" do
    Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u batman whoami', {}).once
    Babushka::ShellHelpers.shell('whoami', :sudo => 'batman')
  end
  it "should sudo from #shell when :as is specified" do
    Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo -u root whoami', {}).once
    Babushka::ShellHelpers.shell('whoami', :as => 'root')
  end
  context "when already running as the sudo user" do
    it "should not sudo when the user is already root" do
      Babushka::ShellHelpers.stub(:current_username).and_return('root')
      Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'whoami', {}).once
      Babushka::ShellHelpers.sudo('whoami')
    end
    it "should not sudo with :as" do
      Babushka::ShellHelpers.stub(:current_username).and_return('batman')
      Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'whoami', {}).once
      Babushka::ShellHelpers.sudo('whoami', :as => 'batman')
    end
    it "should not sudo with a :sudo => 'string' username" do
      Babushka::ShellHelpers.stub(:current_username).and_return('batman')
      Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'whoami', {}).once
      Babushka::ShellHelpers.shell('whoami', :sudo => 'batman')
    end
    it "should not sudo with a :sudo => Parameter username" do
      Babushka::ShellHelpers.stub(:current_username).and_return('batman')
      Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'whoami', {}).once
      Babushka::ShellHelpers.shell('whoami', :sudo => Babushka::Parameter.new('username').default!('batman'))
    end
    it "should not sudo from #shell when :as is specified" do
      Babushka::ShellHelpers.stub(:current_username).and_return('root')
      Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'whoami', {}).once
      Babushka::ShellHelpers.shell('whoami', :as => 'root')
    end
    it "should handle env vars properly" do
      Babushka::ShellHelpers.stub(:current_username).and_return('root')
      Babushka::ShellHelpers.should_receive(:shell_cmd).with({'KEY' => 'value'}, 'echo $KEY', {}).once
      Babushka::ShellHelpers.sudo({'KEY' => 'value'}, 'echo $KEY')
    end
  end
  describe "compound commands" do
    it "should use 'sudo su -' when opts[:su] is supplied" do
      Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo su - root -c "echo \\`whoami\\`"', {}).once
      Babushka::ShellHelpers.sudo("echo \\`whoami\\`", :su => true)
    end
    it "should use 'sudo su -' for redirects" do
      Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo su - root -c "echo \\`whoami\\` > %s/su_with_redirect"' % tmp_prefix, {}).once
      Babushka::ShellHelpers.sudo("echo \\`whoami\\` > %s/su_with_redirect" % tmp_prefix)
    end
    it "should use 'sudo su -' for pipes" do
      Babushka::ShellHelpers.should_receive(:shell_cmd).with({}, 'sudo su - root -c "echo \\`whoami\\` | tee %s/su_with_pipe"' % tmp_prefix, {}).once
      Babushka::ShellHelpers.sudo("echo \\`whoami\\` | tee %s/su_with_pipe" % tmp_prefix)
    end
  end
end

describe "log_shell" do
  it "should log correctly for a successful command" do
    Babushka::LogHelpers.should_receive(:log).with("Getting uptime...", {:newline=>false}).once
    Babushka::ShellHelpers.should_receive(:shell).with('uptime', {:spinner=>true}).and_return("days and days")
    Babushka::LogHelpers.should_receive(:log).with(" done.", {:as=>nil, :indentation=>false}).once
    Babushka::ShellHelpers.log_shell 'Getting uptime', 'uptime'
  end
  it "should log correctly for a failing command" do
    Babushka::LogHelpers.should_receive(:log).with("Setting sail for fail...", {:newline=>false}).once
    Babushka::ShellHelpers.should_receive(:shell).with('false', {:spinner=>true}).and_return(nil)
    Babushka::LogHelpers.should_receive(:log).with(" failed", {:as=>:error, :indentation=>false}).once
    Babushka::ShellHelpers.log_shell 'Setting sail for fail', 'false'
  end
  it "should handle env vars" do
    Babushka::LogHelpers.should_receive(:log).with("Echoing some vars...", {:newline=>false}).once
    Babushka::ShellHelpers.should_receive(:shell).with({'KEY' => 'value'}, 'echo $KEY', {:spinner=>true}).and_return('value')
    Babushka::LogHelpers.should_receive(:log).with(" done.", {:as=>nil, :indentation=>false}).once
    Babushka::ShellHelpers.log_shell 'Echoing some vars', {'KEY' => 'value'}, 'echo $KEY'
  end
end

describe "which" do
  it "should return a string" do
    Babushka::ShellHelpers.which('ls').should be_an_instance_of(String)
  end
  it "should return the path for valid commands" do
    path = `which ls`.chomp
    Babushka::ShellHelpers.which('ls').should == path
  end
  it "should return nil for nonexistent commands" do
    Babushka::ShellHelpers.which('missing').should be_nil
  end
  it "should handle command parameter passed as Symbol" do
    path = `which ls`.chomp
    Babushka::ShellHelpers.which(:ls).should == path
  end
  it "should not return a directory" do
    original_env = ENV['PATH']
    begin
      Dir.mktmpdir do |dir|
        Dir.mkdir(File.join(dir, 'directorycmd'), 0700)
        ENV['PATH'] = "#{ENV['PATH']}:#{dir}"
        Babushka::ShellHelpers.which('directorycmd').should be_nil
      end
    ensure
      ENV['PATH'] = original_env
    end
  end
end

describe "cmd_dir" do
  it "should return a string" do
    Babushka::ShellHelpers.cmd_dir('ruby').should be_an_instance_of(String)
  end
  it "should return the cmd_dir of an existing command" do
    Babushka::ShellHelpers.cmd_dir('ruby').should == `which ruby`.chomp.gsub(/\/ruby$/, '')
  end
  it "should return nil for nonexistent commands" do
    Babushka::ShellHelpers.cmd_dir('missing').should be_nil
  end
end
