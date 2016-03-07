require 'spec_helper'
require 'tmpdir'

SUCCEEDING_LS = 'ls /bin'
FAILING_LS = 'ls /missing'

RSpec.describe "shell" do
  it "should return something true on successful commands" do
    expect(Babushka::ShellHelpers.shell('true')).not_to be_nil
  end
  it "should return nil on failed commands" do
    expect(Babushka::ShellHelpers.shell('false')).to be_nil
  end
  it "should return output of successful commands" do
    expect(Babushka::ShellHelpers.shell('echo lol')).to eq('lol')
  end
  it "should accept multiline commands" do
    expect(Babushka::ShellHelpers.shell("echo babu &&\necho shka")).to eq("babu\nshka")
  end
  it "should accept environment variables as the first argument" do
    expect(Babushka::ShellHelpers.shell({'KEY' => 'value'}, "echo $KEY")).to eq("value")
  end
  it "should provide the shell to supplied blocks when the command succeeds" do
    expect(the_block = "").to receive(:was_called)
    Babushka::ShellHelpers.shell(SUCCEEDING_LS) {|shell|
      the_block.was_called
      expect(shell.stdout).to include('bash')
      expect(shell.stderr).to be_empty
    }
  end
  it "should provide the shell to supplied blocks when the command fails" do
    expect(the_block = "").to receive(:was_called)
    Babushka::ShellHelpers.shell(FAILING_LS) {|shell|
      the_block.was_called
      expect(shell.stdout).to be_empty
      expect(shell.stderr).to include("No such file or directory")
    }
  end
  it "should accept :input parameter" do
    expect(Babushka::ShellHelpers.shell('cat', :input => 'lol')).to eq("lol")
  end
  context ":cd parameter" do
    before { (tmp_prefix / 'dir_param').mkdir }
    it "should run in the current directory when :cd isn't specified" do
      expect(Babushka::ShellHelpers.shell("pwd -P")).to eq(Dir.pwd)
    end
    it "should run in the specified directory" do
      expect(Babushka::ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'dir_param'))).to eq((tmp_prefix / 'dir_param').to_s)
    end
    it "should expand the path" do
      expect(Babushka::ShellHelpers.shell("pwd", :cd => '~')).to eq(ENV['HOME'])
    end
    it "should raise when the path is nonexistent" do
      expect(L{
        Babushka::ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'missing'))
      }).to raise_error(Errno::ENOENT, "No such file or directory - #{tmp_prefix / 'missing'}")
    end
    it "should raise when the path isn't a directory" do
      expect(L{
        (tmp_prefix / 'notadir').touch
        Babushka::ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'notadir'))
      }).to raise_error(Errno::ENOTDIR, "Not a directory - #{tmp_prefix / 'notadir'}")
    end
    context "with :create option" do
      it "should run in the specified directory" do
        expect(Babushka::ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'dir_param'), :create => true)).to eq((tmp_prefix / 'dir_param').to_s)
      end
      it "should create and run when the path is nonexistent" do
        expect(Babushka::ShellHelpers.shell("pwd", :cd => (tmp_prefix / 'dir_param_with_create'), :create => true)).to eq((tmp_prefix / 'dir_param_with_create').to_s)
      end
    end
  end
end

RSpec.describe "shell?" do
  it "should return the output for successful commands" do
    expect(Babushka::ShellHelpers.shell?('echo lol')).to eq('lol')
    expect(Babushka::ShellHelpers.shell?(SUCCEEDING_LS)).to be_truthy
  end
  it "should return false for failed commands" do
    expect(Babushka::ShellHelpers.shell?('false')).to be_falsey
    expect(Babushka::ShellHelpers.shell?(FAILING_LS)).to be_falsey
  end
end

RSpec.describe "shell!" do
  it "should return the output for successful commands" do
    expect(Babushka::ShellHelpers.shell!('echo lol')).to eq('lol')
    expect(Babushka::ShellHelpers.shell!(SUCCEEDING_LS)).to be_truthy
  end
  it "should return false for failed commands" do
    expect(L{ Babushka::ShellHelpers.shell!('false') }).to raise_error(Babushka::Shell::ShellCommandFailed, "Shell command failed: 'false'")
    expect(L{ Babushka::ShellHelpers.shell!(FAILING_LS) }).to raise_error(Babushka::Shell::ShellCommandFailed)
  end
end

RSpec.describe "raw_shell" do
  it "should always return a Shell" do
    expect(Babushka::ShellHelpers.raw_shell('true')).to be_a(Babushka::Shell)
    expect(Babushka::ShellHelpers.raw_shell('false')).to be_a(Babushka::Shell)
  end
  it "should return stdout for succeeding commands" do
    shell = Babushka::ShellHelpers.raw_shell(SUCCEEDING_LS)
    expect(shell.stdout).to include("bash")
    expect(shell.stderr).to be_empty
  end
  it "should return stderr for failed commands" do
    shell = Babushka::ShellHelpers.raw_shell(FAILING_LS)
    expect(shell.stdout).to be_empty
    expect(shell.stderr).to include("No such file or directory")
  end
  it "should support sudo" do
    expect(Babushka::ShellHelpers).to receive(:shell).with('whoami', :sudo => true).once
    Babushka::ShellHelpers.raw_shell('whoami', :sudo => true)
  end
  it "should handle env vars" do
    expect(Babushka::ShellHelpers.raw_shell({'KEY' => 'value'}, 'echo $KEY').stdout).to eq("value\n")
  end
end

RSpec.describe 'login_shell' do
  it "should return something true on successful commands" do
    expect(Babushka::ShellHelpers.login_shell('true')).not_to be_nil
  end
  it "should return nil on failed commands" do
    expect(Babushka::ShellHelpers.login_shell('false')).to be_nil
  end
  it "should run as the given user" do
    expect(Babushka::ShellHelpers).to receive(:shell_cmd).with('echo $SHELL', {}).and_return('')
    expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, "sudo -u batman bash -l -c 'whoami'", {}).once
    Babushka::ShellHelpers.login_shell('whoami', :as => 'batman')
  end
end

RSpec.describe 'argument behaviour' do
  context "with a single string" do
    it "should support compound commands" do
      expect(Babushka::ShellHelpers.shell("echo trousers | tr a-z A-Z")).to eq('TROUSERS')
    end
    it "should fail with unclosed quotes" do
      expect(Babushka::ShellHelpers.shell('echo blah"')).to be_nil
    end
  end
  context "with an array" do
    it "should treat as a command and args" do
      expect(Babushka::ShellHelpers.shell(%w[echo trousers | tr a-z A-Z])).to eq('trousers | tr a-z A-Z')
    end
    it "should escape unclosed quotes" do
      expect(Babushka::ShellHelpers.shell(['echo', 'blah"'])).to eq('blah"')
    end
  end
end

RSpec.describe "sudo" do
  it "should accept string input" do
    expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo -u root whoami', {}).once
    Babushka::ShellHelpers.sudo('whoami')
  end
  it "should accept splatted input" do
    expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo -u root echo test', {}).once
    Babushka::ShellHelpers.sudo('echo', 'test')
  end
  it "should accept array input" do
    expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo -u root whoami', {}).once
    Babushka::ShellHelpers.sudo(['whoami'])
  end
  describe 'command joining' do
    it "should escape & join splatted args" do
      expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo -u root echo test with\ a\ \"quote', {}).once
      Babushka::ShellHelpers.sudo('echo', 'test', 'with a "quote')
    end
    it "should escape & join array args" do
      expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo -u root echo test with\ a\ \"quote', {}).once
      Babushka::ShellHelpers.sudo(['echo', 'test', 'with a "quote'])
    end
    it "should not escape string args" do
      expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo -u root echo test with a \"quote', {}).once
      Babushka::ShellHelpers.sudo('echo test with a \"quote')
    end
  end
  it "should run as root when no user is given" do
    expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo -u root whoami', {}).once
    Babushka::ShellHelpers.sudo('whoami')
  end
  it "should run as the given user" do
    expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo -u batman whoami', {}).once
    Babushka::ShellHelpers.sudo('whoami', :as => 'batman')
  end
  it "should treat :sudo => 'string' as a username" do
    expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo -u batman whoami', {}).once
    Babushka::ShellHelpers.shell('whoami', :sudo => 'batman')
  end
  it "should sudo from #shell when :as is specified" do
    expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo -u root whoami', {}).once
    Babushka::ShellHelpers.shell('whoami', :as => 'root')
  end
  context "when already running as the sudo user" do
    it "should not sudo when the user is already root" do
      allow(Babushka::ShellHelpers).to receive(:current_username).and_return('root')
      expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'whoami', {}).once
      Babushka::ShellHelpers.sudo('whoami')
    end
    it "should not sudo with :as" do
      allow(Babushka::ShellHelpers).to receive(:current_username).and_return('batman')
      expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'whoami', {}).once
      Babushka::ShellHelpers.sudo('whoami', :as => 'batman')
    end
    it "should not sudo with a :sudo => 'string' username" do
      allow(Babushka::ShellHelpers).to receive(:current_username).and_return('batman')
      expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'whoami', {}).once
      Babushka::ShellHelpers.shell('whoami', :sudo => 'batman')
    end
    it "should not sudo with a :sudo => Parameter username" do
      allow(Babushka::ShellHelpers).to receive(:current_username).and_return('batman')
      expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'whoami', {}).once
      Babushka::ShellHelpers.shell('whoami', :sudo => Babushka::Parameter.new('username').default!('batman'))
    end
    it "should not sudo from #shell when :as is specified" do
      allow(Babushka::ShellHelpers).to receive(:current_username).and_return('root')
      expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'whoami', {}).once
      Babushka::ShellHelpers.shell('whoami', :as => 'root')
    end
    it "should handle env vars properly" do
      allow(Babushka::ShellHelpers).to receive(:current_username).and_return('root')
      expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({'KEY' => 'value'}, 'echo $KEY', {}).once
      Babushka::ShellHelpers.sudo({'KEY' => 'value'}, 'echo $KEY')
    end
  end
  describe "compound commands" do
    it "should use 'sudo su -' when opts[:su] is supplied" do
      expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo su - root -c "echo \\`whoami\\`"', {}).once
      Babushka::ShellHelpers.sudo("echo \\`whoami\\`", :su => true)
    end
    it "should use 'sudo su -' for redirects" do
      expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo su - root -c "echo \\`whoami\\` > %s/su_with_redirect"' % tmp_prefix, {}).once
      Babushka::ShellHelpers.sudo("echo \\`whoami\\` > %s/su_with_redirect" % tmp_prefix)
    end
    it "should use 'sudo su -' for pipes" do
      expect(Babushka::ShellHelpers).to receive(:shell_cmd).with({}, 'sudo su - root -c "echo \\`whoami\\` | tee %s/su_with_pipe"' % tmp_prefix, {}).once
      Babushka::ShellHelpers.sudo("echo \\`whoami\\` | tee %s/su_with_pipe" % tmp_prefix)
    end
  end
end

RSpec.describe "log_shell" do
  it "should log correctly for a successful command" do
    expect(Babushka::LogHelpers).to receive(:log).with("Getting uptime...", {:newline=>false}).once
    expect(Babushka::ShellHelpers).to receive(:shell).with('uptime', {:spinner=>true}).and_return("days and days")
    expect(Babushka::LogHelpers).to receive(:log).with(" done.", {:as=>nil, :indentation=>false}).once
    Babushka::ShellHelpers.log_shell 'Getting uptime', 'uptime'
  end
  it "should log correctly for a failing command" do
    expect(Babushka::LogHelpers).to receive(:log).with("Setting sail for fail...", {:newline=>false}).once
    expect(Babushka::ShellHelpers).to receive(:shell).with('false', {:spinner=>true}).and_return(nil)
    expect(Babushka::LogHelpers).to receive(:log).with(" failed", {:as=>:error, :indentation=>false}).once
    Babushka::ShellHelpers.log_shell 'Setting sail for fail', 'false'
  end
  it "should handle env vars" do
    expect(Babushka::LogHelpers).to receive(:log).with("Echoing some vars...", {:newline=>false}).once
    expect(Babushka::ShellHelpers).to receive(:shell).with({'KEY' => 'value'}, 'echo $KEY', {:spinner=>true}).and_return('value')
    expect(Babushka::LogHelpers).to receive(:log).with(" done.", {:as=>nil, :indentation=>false}).once
    Babushka::ShellHelpers.log_shell 'Echoing some vars', {'KEY' => 'value'}, 'echo $KEY'
  end
end

RSpec.describe "which" do
  it "should return a string" do
    expect(Babushka::ShellHelpers.which('ls')).to be_an_instance_of(String)
  end
  it "should return the path for valid commands" do
    path = `which ls`.chomp
    expect(Babushka::ShellHelpers.which('ls')).to eq(path)
  end
  it "should return nil for nonexistent commands" do
    expect(Babushka::ShellHelpers.which('missing')).to be_nil
  end
  it "should handle command parameter passed as Symbol" do
    path = `which ls`.chomp
    expect(Babushka::ShellHelpers.which(:ls)).to eq(path)
  end
  it "should not return a directory" do
    original_env = ENV['PATH']
    begin
      Dir.mktmpdir do |dir|
        Dir.mkdir(File.join(dir, 'directorycmd'), 0700)
        ENV['PATH'] = "#{ENV['PATH']}:#{dir}"
        expect(Babushka::ShellHelpers.which('directorycmd')).to be_nil
      end
    ensure
      ENV['PATH'] = original_env
    end
  end
end

RSpec.describe "cmd_dir" do
  it "should return a string" do
    expect(Babushka::ShellHelpers.cmd_dir('ruby')).to be_an_instance_of(String)
  end
  it "should return the cmd_dir of an existing command" do
    expect(Babushka::ShellHelpers.cmd_dir('ruby')).to eq(`which ruby`.chomp.gsub(/\/ruby$/, ''))
  end
  it "should return nil for nonexistent commands" do
    expect(Babushka::ShellHelpers.cmd_dir('missing')).to be_nil
  end
end
