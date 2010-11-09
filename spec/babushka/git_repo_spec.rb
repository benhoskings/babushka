require 'spec_helper'

class PathSupport; extend PathHelpers end

def stub_repo name = 'a'
  PathSupport.in_dir tmp_prefix / 'repos' / name, :create => true do
    shell 'git init'
    shell 'echo "Hello from the babushka specs!" >> content.txt'
    shell 'mkdir lib'
    shell 'echo "Here are the rubies." >> lib/rubies.rb'
    shell 'git add .'
    shell 'git commit -m "Initial commit, by the spec suite."'
  end
end

describe GitRepo, 'creation' do
  before { stub_repo 'a' }
  it "should return nil on non-repo paths" do
    Babushka::GitRepo.new(tmp_prefix / 'repos').path.should == nil
  end
  it "should recognise the repo path" do
    Babushka::GitRepo.new(tmp_prefix / 'repos/a').path.should == tmp_prefix / 'repos/a'
  end
  it "should find the parent when called on the subdir" do
    Babushka::GitRepo.new(tmp_prefix / 'repos/a/lib').path.should == tmp_prefix / 'repos/a'
  end
end

describe GitRepo, '#clean? / #dirty?' do
  before { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return false for clean repos" do
    subject.should be_clean
    subject.should_not be_dirty
  end
  it "should return true when there are changes" do
    PathSupport.in_dir(tmp_prefix / 'repos/a') { shell "echo dirt >> content.txt" }
    subject.should_not be_clean
    subject.should be_dirty
  end
end
