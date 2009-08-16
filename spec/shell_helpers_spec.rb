require 'spec/spec_support'

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

describe "sudo" do
  it "should run as root when no user is given" do
    sudo('whoami').should == 'root'
  end
  it "should run as the given user" do
    current_user = `whoami`.chomp
    sudo('whoami', :as => current_user) == current_user
  end
end

describe "grep" do
  it "should grep existing files" do
    grep('include', 'spec/spec_support.rb').should include "include Babushka\n"
  end
  it "should return nil when there are no matches" do
    grep('lol', 'spec/spec_support.rb').should be_nil
  end
  it "should return nil for nonexistent files" do
    grep('lol', '/nonexistent').should be_nil
  end
end

describe "which" do
  it "should return the path for valid commands" do
    path = `which ls`.chomp
    which('ls').should == path
  end
  it "should return nil for nonexistent commands" do
    which('nonexistent').should be_nil
  end
end

require 'fileutils'
describe "in_dir" do
  before do
    @tmp_dir = tmp_prefix
    FileUtils.mkdir_p @tmp_dir
    @tmp_dir_2 = File.join(tmp_prefix, '2')
    FileUtils.mkdir_p @tmp_dir_2

    @original_pwd = Dir.pwd

    @nonexistent_dir = File.join(tmp_prefix, 'nonexistent')
    Dir.rmdir(@nonexistent_dir) if File.directory?(@nonexistent_dir)
  end

  it "should yield if no chdir is required" do
    has_yielded = false
    l = L{
      Dir.pwd.should == @original_pwd
      has_yielded = true
    }
    in_dir @original_pwd, &l
    has_yielded.should be_true
  end
  it "should change dir for the duration of the block" do
    has_yielded = false
    l = L{
      Dir.pwd.should == @tmp_dir
      has_yielded = true
    }
    in_dir @tmp_dir, &l
    has_yielded.should be_true
    Dir.pwd.should == @original_pwd
  end
  it "should work recursively" do
    in_dir(@tmp_dir) {
      Dir.pwd.should == @tmp_dir
      in_dir(@tmp_dir_2) {
        Dir.pwd.should == @tmp_dir_2
      }
      Dir.pwd.should == @tmp_dir
    }
    Dir.pwd.should == @original_pwd
  end
  it "should fail on nonexistent dirs" do
    L{ in_dir(@nonexistent_dir) }.should raise_error Errno::ENOENT
  end
  it "should create nonexistent dirs if :create => true is specified" do
    in_dir(@nonexistent_dir, :create => true) {
      Dir.pwd.should == @nonexistent_dir
    }
    Dir.pwd.should == @original_pwd
  end
end

describe "cmd_dir" do
  it "should return the cmd_dir of an existing command" do
    cmd_dir('ruby').should == `which ruby`.chomp.gsub('/ruby', '')
  end
  it "should return nil for nonexistent commands" do
    cmd_dir('nonexistent').should be_nil
  end
end
