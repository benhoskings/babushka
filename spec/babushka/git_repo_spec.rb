require 'spec_helper'

class PathSupport; extend PathHelpers end

def stub_repo name = 'a', opts = {}
  PathSupport.in_dir tmp_prefix / 'repos' / name, :create => true do
    shell 'git init'
    shell 'echo "Hello from the babushka specs!" >> content.txt'
    shell 'mkdir lib'
    shell 'echo "Here are the rubies." >> lib/rubies.rb'
    shell 'git add .'
    shell 'git commit -m "Initial commit, by the spec suite."'
  end
  stub_remote(name) if opts[:with_remote]
end

def stub_remote name
  PathSupport.in_dir tmp_prefix / 'repos' / "#{name}_remote", :create => true do
    shell 'git init --bare'
  end
  PathSupport.in_dir tmp_prefix / 'repos' / name do
    shell "git remote add origin ../#{name}_remote"
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

describe GitRepo, '#pushed?' do
  before { stub_repo 'a', :with_remote => true }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return false if the current branch has no remote" do
    subject.remote_branch_exists?.should be_false
    subject.should_not be_pushed
  end
  context "when remote branch exists" do
    before {
      PathSupport.in_dir(tmp_prefix / 'repos/a') {
        shell "git push origin master"
        shell 'echo "Ch-ch-ch-changes" >> content.txt'
        shell 'git commit -a -m "Changes!"'
      }
    }
    it "should return false if there are unpushed commits on the current branch" do
      subject.remote_branch_exists?.should be_true
      subject.should_not be_pushed
    end
    context "when the branch is fully pushed" do
      before {
        PathSupport.in_dir(tmp_prefix / 'repos/a') {
          shell "git push origin master"
        }
      }
      it "should return true if the current branch is fully pushed" do
        subject.remote_branch_exists?.should be_true
        subject.should be_pushed
      end
    end
  end
end
