require 'spec_helper'

class PathSupport; extend PathHelpers end

def stub_repo name = 'a', opts = {}
  shell "rm -rf '#{tmp_prefix / 'repos' / name}'"
  PathSupport.in_dir tmp_prefix / 'repos' / name, :create => true do
    shell 'git init'
    unless opts[:empty]
      shell 'echo "Hello from the babushka specs!" >> content.txt'
      shell 'mkdir lib'
      shell 'echo "Here are the rubies." >> lib/rubies.rb'
      shell 'git add .'
      shell 'git commit -m "Initial commit, by the spec suite."'
    end
  end
end

def stub_repo_with_remote name
  shell "rm -rf '#{tmp_prefix / 'repos' / "#{name}_remote"}'"
  PathSupport.in_dir tmp_prefix / 'repos' / "#{name}_remote", :create => true do
    shell "tar -zxvf #{File.dirname(__FILE__) / '../repos/remote.git.tgz'}"
  end

  shell "rm -rf '#{tmp_prefix / 'repos' / name}'"
  PathSupport.in_dir tmp_prefix / 'repos' do
    shell "git clone ./#{name}_remote/remote.git ./#{name}"
  end
end

def repo_context name, &block
  PathSupport.in_dir(tmp_prefix / 'repos'/ name, &block)
end

describe GitRepo, 'creation' do
  before { stub_repo 'a' }
  it "should return nil on nonexistent paths" do
    Babushka::GitRepo.new(tmp_prefix / 'repos/nonexistent').repo.should == nil
  end
  it "should return nil on non-repo paths" do
    Babushka::GitRepo.new(tmp_prefix / 'repos').repo.should == nil
  end
  it "should recognise the repo path as a string" do
    Babushka::GitRepo.new((tmp_prefix / 'repos/a').to_s).repo.should == tmp_prefix / 'repos/a'
  end
  it "should recognise the repo path as a Fancypath" do
    Babushka::GitRepo.new(tmp_prefix / 'repos/a').repo.should == tmp_prefix / 'repos/a'
  end
  it "should find the parent when called on the subdir" do
    Babushka::GitRepo.new(tmp_prefix / 'repos/a/lib').repo.should == tmp_prefix / 'repos/a'
  end
  it "should return the repo path as a Fancypath" do
    Babushka::GitRepo.new((tmp_prefix / 'repos/a').to_s).repo.should be_an_instance_of(Fancypath)
    Babushka::GitRepo.new(tmp_prefix / 'repos/a').repo.should be_an_instance_of(Fancypath)
  end
end

describe GitRepo, 'without a repo' do
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/nonexistent') }
  it "should not exist" do
    subject.exists?.should be_false
  end
  [:clean?, :dirty?, :current_branch, :current_head, :remote_branch_exists?, :ahead?].each {|method|
    it "should raise on #{method}" do
      L{ subject.send(method) }.should raise_error Babushka::GitRepoError, "There is no repo at #{tmp_prefix / 'repos/nonexistent'}."
    end
  }
end

describe GitRepo, "with a repo" do
  before { stub_repo 'a' }
  it "should exist with string path" do
    Babushka::GitRepo.new((tmp_prefix / 'repos/a').to_s).exists?.should be_true
  end
  it "should exist with Fancypath path" do
    Babushka::GitRepo.new(tmp_prefix / 'repos/a').exists?.should be_true
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

describe GitRepo, '#branches' do
  before { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return the only branch in a list" do
    subject.branches.should == ['master']
  end
  context "after creating another branch" do
    before {
      repo_context('a') { shell "git checkout -b next"}
    }
    it "should return both branches" do
      subject.branches.should == ['master', 'next']
    end
    context "after changing back to master" do
      before {
        repo_context('a') { shell "git checkout master"}
      }
      it "should return both branches" do
        subject.branches.should == ['master', 'next']
      end
    end
  end
  context "on a repo with no commits" do
    before { stub_repo 'a', :empty => true }
    it "should return no branches" do
      subject.branches.should == []
    end
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
      repo_context('a') { shell "git checkout -b next"}
    }
    it "should return 'next'" do
      subject.current_branch.should == 'next'
    end
    context "after changing back to master" do
      before {
        repo_context('a') { shell "git checkout master"}
      }
      it "should return 'next'" do
        subject.current_branch.should == 'master'
      end
    end
  end
end

describe GitRepo, '#current_head' do
  before { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return a commit id" do
    subject.current_head.should =~ /^[0-9a-f]{7}$/
  end
end

describe GitRepo, '#ahead?' do
  before {
    stub_repo_with_remote 'a'
    PathSupport.in_dir(tmp_prefix / 'repos/a') {
      shell "git checkout -b topic"
    }
  }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should have a local topic branch" do
    subject.current_branch.should == 'topic'
  end
  it "should return true if the current branch has no remote" do
    subject.remote_branch_exists?.should be_false
    subject.should be_ahead
  end
  context "when remote branch exists" do
    before {
      PathSupport.in_dir(tmp_prefix / 'repos/a') {
        shell "git push origin topic"
        shell 'echo "Ch-ch-ch-changes" >> content.txt'
        shell 'git commit -a -m "Changes!"'
      }
    }
    it "should have a local topic branch" do
      subject.current_branch.should == 'topic'
    end
    it "should return false if there are unpushed commits on the current branch" do
      subject.remote_branch_exists?.should be_true
      subject.should be_ahead
    end
    context "when the branch is fully pushed" do
      before {
        PathSupport.in_dir(tmp_prefix / 'repos/a') {
          shell "git push origin topic"
        }
      }
      it "should return true" do
        subject.remote_branch_exists?.should be_true
        subject.should_not be_ahead
      end
    end
  end

  describe GitRepo, '#track!' do
    before { stub_repo_with_remote 'a' }
    it "should not already have a next branch" do
      subject.branches.should_not include('next')
    end
    context "after tracking" do
      before { subject.track! "origin/next" }
      it "should be tracking the next branch now" do
        subject.branches.should include('next')
      end
    end
  end

  describe GitRepo, '#checkout!' do
    before {
      stub_repo_with_remote 'a'
      PathSupport.in_dir(tmp_prefix / 'repos/a') {
        shell "git checkout -b next"
      }
    }
    it "should already have a next branch" do
      subject.branches.should =~ %w[master next]
      subject.current_branch.should == 'next'
    end
    context "after checking out" do
      before { subject.checkout! "master" }
      it "should be on the master branch now" do
        subject.current_branch.should == 'master'
      end
    end
  end

  describe GitRepo, '#reset_hard!' do
    before {
      stub_repo_with_remote 'a'
      PathSupport.in_dir(tmp_prefix / 'repos/a') {
        shell "echo 'more rubies' >> lib/rubies.rb"
      }
    }
    it "should make a dirty repo clean" do
      subject.should be_dirty
      subject.reset_hard!
      subject.should be_clean
    end
  end
end