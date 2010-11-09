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

def in_repo name, &block
  PathSupport.in_dir(tmp_prefix / 'repos'/ name, &block)
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

describe GitRepo, '#current_branch' do
  before { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return 'master'" do
    subject.current_branch.should == 'master'
  end
  context "after creating another branch" do
    before {
      in_repo('a') { shell "git checkout -b next"}
    }
    it "should return 'next'" do
      subject.current_branch.should == 'next'
    end
    context "after changing back to master" do
      before {
        in_repo('a') { shell "git checkout master"}
      }
      it "should return 'next'" do
        subject.current_branch.should == 'master'
      end
    end
  end
end
