require 'spec_helper'

RSpec.describe "cd" do
  let!(:original_pwd) { Dir.pwd }

  it "should yield if no dir is given" do
    has_yielded = false
    Babushka::PathHelpers.cd(nil) {|path|
      expect(path).to be_an_instance_of(Fancypath)
      expect(Dir.pwd).to eq(original_pwd)
      has_yielded = true
    }
    expect(has_yielded).to be_truthy
  end

  it "should yield if no chdir is required" do
    has_yielded = false
    Babushka::PathHelpers.cd(original_pwd) {|path|
      expect(path).to be_an_instance_of(Fancypath)
      expect(Dir.pwd).to eq(original_pwd)
      has_yielded = true
    }
    expect(has_yielded).to be_truthy
  end
  it "should change dir for the duration of the block" do
    has_yielded = false
    Babushka::PathHelpers.cd(tmp_prefix) {
      expect(Dir.pwd).to eq(tmp_prefix)
      has_yielded = true
    }
    expect(has_yielded).to be_truthy
    expect(Dir.pwd).to eq(original_pwd)
  end
  context "recursively" do
    let(:tmp_subdir) { (tmp_prefix / '2').tap(&:mkdir) }
    it "should work" do
      has_yielded = false
      Babushka::PathHelpers.cd(tmp_prefix) {
        expect(Dir.pwd).to eq(tmp_prefix)
        Babushka::PathHelpers.cd(tmp_subdir) {
          expect(Dir.pwd).to eq(tmp_subdir)
          has_yielded = true
        }
        expect(Dir.pwd).to eq(tmp_prefix)
      }
      expect(has_yielded).to be_truthy
      expect(Dir.pwd).to eq(original_pwd)
    end
  end
  context "nonexistent dirs" do
    let(:nonexistent_dir) {
      (tmp_prefix / 'missing').tap(&:rm)
    }
    it "should fail" do
      expect(L{ Babushka::PathHelpers.cd(nonexistent_dir) }).to raise_error(Errno::ENOENT)
    end
    context "when :create => true is specified" do
      it "should create and cd" do
        Babushka::PathHelpers.cd(nonexistent_dir, :create => true) {
          expect(Dir.pwd).to eq(nonexistent_dir)
        }
        expect(Dir.pwd).to eq(original_pwd)
      end
      after {
        nonexistent_dir.rm
      }
    end
  end
end

RSpec.describe "in_build_dir" do
  let!(:original_pwd) { Dir.pwd }

  it "should change to the build dir with no args" do
    Babushka::PathHelpers.in_build_dir {
      expect(Dir.pwd).to eq("~/.babushka/build".p)
    }
    expect(Dir.pwd).to eq(original_pwd)
  end
  it "should append the supplied path when supplied" do
    Babushka::PathHelpers.in_build_dir "tmp" do
      expect(Dir.pwd).to eq("~/.babushka/build/tmp".p)
    end
    expect(Dir.pwd).to eq(original_pwd)
  end
end

RSpec.describe "in_download_dir" do
  let!(:original_pwd) { Dir.pwd }

  it "should change to the download dir with no args" do
    Babushka::PathHelpers.in_download_dir {
      expect(Dir.pwd).to eq("~/.babushka/downloads".p)
    }
    expect(Dir.pwd).to eq(original_pwd)
  end
  it "should append the supplied path when supplied" do
    Babushka::PathHelpers.in_download_dir "tmp" do
      expect(Dir.pwd).to eq("~/.babushka/downloads/tmp".p)
    end
    expect(Dir.pwd).to eq(original_pwd)
  end
end
