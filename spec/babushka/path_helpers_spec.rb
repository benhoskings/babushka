require 'spec_helper'

describe "cd" do
  let!(:original_pwd) { Dir.pwd }

  it "should yield if no dir is given" do
    has_yielded = false
    cd(nil) {|path|
      path.should be_an_instance_of(Fancypath)
      Dir.pwd.should == original_pwd
      has_yielded = true
    }
    has_yielded.should be_true
  end

  it "should yield if no chdir is required" do
    has_yielded = false
    cd(original_pwd) {|path|
      path.should be_an_instance_of(Fancypath)
      Dir.pwd.should == original_pwd
      has_yielded = true
    }
    has_yielded.should be_true
  end
  it "should change dir for the duration of the block" do
    has_yielded = false
    cd(tmp_prefix) {
      Dir.pwd.should == tmp_prefix
      has_yielded = true
    }
    has_yielded.should be_true
    Dir.pwd.should == original_pwd
  end
  context "recursively" do
    let(:tmp_subdir) { (tmp_prefix / '2').tap(&:mkdir) }
    it "should work" do
      has_yielded = false
      cd(tmp_prefix) {
        Dir.pwd.should == tmp_prefix
        cd(tmp_subdir) {
          Dir.pwd.should == tmp_subdir
          has_yielded = true
        }
        Dir.pwd.should == tmp_prefix
      }
      has_yielded.should be_true
      Dir.pwd.should == original_pwd
    end
  end
  context "nonexistent dirs" do
    let(:nonexistent_dir) {
      (tmp_prefix / 'missing').tap(&:rm)
    }
    it "should fail" do
      L{ cd(nonexistent_dir) }.should raise_error(Errno::ENOENT)
    end
    context "when :create => true is specified" do
      it "should create and cd" do
        cd(nonexistent_dir, :create => true) {
          Dir.pwd.should == nonexistent_dir
        }
        Dir.pwd.should == original_pwd
      end
      after {
        nonexistent_dir.rm
      }
    end
  end
end

describe "in_build_dir" do
  let!(:original_pwd) { Dir.pwd }

  it "should change to the build dir with no args" do
    in_build_dir {
      Dir.pwd.should == "~/.babushka/build".p
    }
    Dir.pwd.should == original_pwd
  end
  it "should append the supplied path when supplied" do
    in_build_dir "tmp" do
      Dir.pwd.should == "~/.babushka/build/tmp".p
    end
    Dir.pwd.should == original_pwd
  end
end

describe "in_download_dir" do
  let!(:original_pwd) { Dir.pwd }

  it "should change to the download dir with no args" do
    in_download_dir {
      Dir.pwd.should == "~/.babushka/downloads".p
    }
    Dir.pwd.should == original_pwd
  end
  it "should append the supplied path when supplied" do
    in_download_dir "tmp" do
      Dir.pwd.should == "~/.babushka/downloads/tmp".p
    end
    Dir.pwd.should == original_pwd
  end
end
