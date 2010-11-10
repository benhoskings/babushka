require 'spec_helper'

class PathTester; extend PathHelpers end

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

  it "should yield if no dir is given" do
    has_yielded = false
    PathTester.in_dir(nil) {|path|
      path.should be_an_instance_of(Fancypath)
      Dir.pwd.should == @original_pwd
      has_yielded = true
    }
    has_yielded.should be_true
  end

  it "should yield if no chdir is required" do
    has_yielded = false
    PathTester.in_dir(@original_pwd) {|path|
      path.should be_an_instance_of(Fancypath)
      Dir.pwd.should == @original_pwd
      has_yielded = true
    }
    has_yielded.should be_true
  end
  it "should change dir for the duration of the block" do
    has_yielded = false
    PathTester.in_dir(@tmp_dir) {
      Dir.pwd.should == @tmp_dir
      has_yielded = true
    }
    has_yielded.should be_true
    Dir.pwd.should == @original_pwd
  end
  it "should work recursively" do
    PathTester.in_dir(@tmp_dir) {
      Dir.pwd.should == @tmp_dir
      PathTester.in_dir(@tmp_dir_2) {
        Dir.pwd.should == @tmp_dir_2
      }
      Dir.pwd.should == @tmp_dir
    }
    Dir.pwd.should == @original_pwd
  end
  it "should fail on nonexistent dirs" do
    L{ PathTester.in_dir(@nonexistent_dir) }.should raise_error(Errno::ENOENT)
  end
  it "should create nonexistent dirs if :create => true is specified" do
    PathTester.in_dir(@nonexistent_dir, :create => true) {
      Dir.pwd.should == @nonexistent_dir
    }
    Dir.pwd.should == @original_pwd
  end
  after {
    Dir.rmdir(@nonexistent_dir) if File.directory?(@nonexistent_dir)
  }
end

describe "in_build_dir" do
  before {
    @original_pwd = Dir.pwd
  }
  it "should change to the build dir with no args" do
    PathTester.in_build_dir {
      Dir.pwd.should == "~/.babushka/build".p
    }
    Dir.pwd.should == @original_pwd
  end
  it "should append the supplied path when supplied" do
    PathTester.in_build_dir "tmp" do
      Dir.pwd.should == "~/.babushka/build/tmp".p
    end
    Dir.pwd.should == @original_pwd
  end
end

describe "in_download_dir" do
  before {
    @original_pwd = Dir.pwd
  }
  it "should change to the download dir with no args" do
    PathTester.in_download_dir {
      Dir.pwd.should == "~/.babushka/downloads".p
    }
    Dir.pwd.should == @original_pwd
  end
  it "should append the supplied path when supplied" do
    PathTester.in_download_dir "tmp" do
      Dir.pwd.should == "~/.babushka/downloads/tmp".p
    end
    Dir.pwd.should == @original_pwd
  end
end
