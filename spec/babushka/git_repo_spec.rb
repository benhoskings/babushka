require 'spec_helper'

def stub_commitless_repo name
  (tmp_prefix / 'repos' / name).rm
  cd tmp_prefix / 'repos' / name, :create => true do
    shell "git init"
  end
end

def stub_repo name
  (tmp_prefix / 'repos' / "#{name}_remote").rm
  cd tmp_prefix / 'repos' / "#{name}_remote", :create => true do
    shell "tar -zxvf #{File.dirname(__FILE__) / '../repos/remote.git.tgz'}"
  end

  (tmp_prefix / 'repos' / name).rm
  cd tmp_prefix / 'repos' do
    shell "git clone #{name}_remote/remote.git #{name}"
  end
end

def repo_context name, &block
  cd(tmp_prefix / 'repos'/ name, &block)
end

describe GitRepo, 'creation' do
  before(:all) { stub_repo 'a' }
  it "should return nil on nonexistent paths" do
    Babushka::GitRepo.new(tmp_prefix / 'repos/missing').root.should == nil
  end
  it "should return nil on non-repo paths" do
    Babushka::GitRepo.new(tmp_prefix / 'repos').root.should == nil
  end
  it "should recognise the repo path as a string" do
    Babushka::GitRepo.new((tmp_prefix / 'repos/a').to_s).root.should == tmp_prefix / 'repos/a'
  end
  it "should recognise the repo path as a Fancypath" do
    Babushka::GitRepo.new(tmp_prefix / 'repos/a').root.should == tmp_prefix / 'repos/a'
  end
  it "should find the parent when called on the subdir" do
    Babushka::GitRepo.new(tmp_prefix / 'repos/a/lib').root.should == tmp_prefix / 'repos/a'
  end
  it "should find the git dir within the repo" do
    Babushka::GitRepo.new(tmp_prefix / 'repos/a').git_dir.should == tmp_prefix / 'repos/a/.git'
    Babushka::GitRepo.new(tmp_prefix / 'repos/a/lib').git_dir.should == tmp_prefix / 'repos/a/.git'
  end
  it "should store path as a Fancypath" do
    Babushka::GitRepo.new((tmp_prefix / 'repos/a').to_s).path.should be_an_instance_of(Fancypath)
    Babushka::GitRepo.new(tmp_prefix / 'repos/a').path.should be_an_instance_of(Fancypath)
  end
  it "should return the repo path as a Fancypath" do
    Babushka::GitRepo.new((tmp_prefix / 'repos/a').to_s).root.should be_an_instance_of(Fancypath)
    Babushka::GitRepo.new(tmp_prefix / 'repos/a').root.should be_an_instance_of(Fancypath)
  end
end

describe GitRepo, 'without a repo' do
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/missing') }
  it "should not exist" do
    subject.exists?.should be_false
  end
  [:clean?, :dirty?, :current_branch, :current_head, :remote_branch_exists?, :ahead?].each {|method|
    it "should raise on #{method}" do
      L{ subject.send(method) }.should raise_error(Babushka::GitRepoError, "There is no repo at #{tmp_prefix / 'repos/missing'}.")
    end
  }
  context "with lazy eval" do
    subject { Babushka::GitRepo.new(tmp_prefix / 'repos/lazy') }
    it "should fail before the repo is created, but work afterwards" do
      subject.exists?.should be_false
      L{ subject.clean? }.should raise_error(Babushka::GitRepoError, "There is no repo at #{tmp_prefix / 'repos/lazy'}.")
      stub_repo 'lazy'
      subject.exists?.should be_true
      subject.should be_clean
    end
  end
end

describe GitRepo, "with a repo" do
  before(:all) { stub_repo 'a' }
  it "should exist with string path" do
    Babushka::GitRepo.new((tmp_prefix / 'repos/a').to_s).exists?.should be_true
  end
  it "should exist with Fancypath path" do
    Babushka::GitRepo.new(tmp_prefix / 'repos/a').exists?.should be_true
  end
end

describe GitRepo, '#clean? / #dirty?' do
  context "on commitless repos" do
    before(:all) { stub_commitless_repo 'a' }
    subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
    it "should be clean" do
      subject.should be_clean
      subject.should_not be_dirty
    end
  end
  context "on normal repos" do
    before(:all) { stub_repo 'a' }
    subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
    it "should be clean" do
      subject.should be_clean
      subject.should_not be_dirty
    end
    context "when there are changes" do
      before {
        cd(tmp_prefix / 'repos/a') { shell "echo dirt >> content.txt" }
      }
      it "should be dirty" do
        subject.should_not be_clean
        subject.should be_dirty
      end
      context "when the changes are staged" do
        before {
          cd(tmp_prefix / 'repos/a') { shell "git add --update ." }
        }
        it "should be dirty" do
          subject.should_not be_clean
          subject.should be_dirty
        end
      end
    end
  end
end

describe GitRepo, '#include?' do
  before(:all) { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return true for valid commits" do
    subject.include?('20758f2d9d696c51ac83a0fd36626d421057b24d').should be_true
    subject.include?('20758f2').should be_true
  end
  it "should return false for nonexistent commits" do
    subject.include?('20758f2d9d696c51ac83a0fd36626d421057b24e').should be_false
    subject.include?('20758f3').should be_false
  end
end

describe GitRepo, '#branches' do
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  context "on a repo with commits" do
    before(:all) { stub_repo 'a' }
    it "should return the only branch in a list" do
      subject.branches.should == ['master']
    end
    context "after creating another branch" do
      before {
        repo_context('a') { shell "git checkout -b next" }
      }
      it "should return both branches" do
        subject.branches.should == ['master', 'next']
      end
      context "after changing back to master" do
        before {
          repo_context('a') { shell "git checkout master" }
        }
        it "should return both branches" do
          subject.branches.should == ['master', 'next']
        end
      end
    end
  end
  context "on a repo with no commits" do
    before { stub_commitless_repo 'a' }
    it "should return no branches" do
      subject.branches.should == []
    end
  end
end

describe GitRepo, '#current_branch' do
  before(:all) { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return 'master'" do
    subject.current_branch.should == 'master'
  end
  context "after creating another branch" do
    before {
      repo_context('a') { shell "git checkout -b next" }
    }
    it "should return 'next'" do
      subject.current_branch.should == 'next'
    end
    context "after changing back to master" do
      before {
        repo_context('a') { shell "git checkout master" }
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
  it "should return a short commit id" do
    subject.current_head.should =~ /^[0-9a-f]{7}$/
  end
end

describe GitRepo, '#current_full_head' do
  before { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return a full commit id" do
    subject.current_full_head.should =~ /^[0-9a-f]{40}$/
  end
end

describe GitRepo, '#resolve' do
  before { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return a full commit id" do
    subject.resolve('master').should =~ /^[0-9a-f]{7,40}$/
  end
end

describe GitRepo, '#ahead?' do
  before(:all) {
    stub_repo 'a'
    cd(tmp_prefix / 'repos/a') {
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
    before(:all) {
      cd(tmp_prefix / 'repos/a') {
        shell "git push origin topic"
        shell 'echo "Ch-ch-ch-changes" >> content.txt'
        shell 'git commit -a -m "Changes!"'
      }
    }
    it "should have a local topic branch" do
      subject.current_branch.should == 'topic'
    end
    it "should return true if there are unpushed commits on the current branch" do
      subject.remote_branch_exists?.should be_true
      subject.should be_ahead
    end
    context "when the branch is fully pushed" do
      before {
        cd(tmp_prefix / 'repos/a') {
          shell "git push origin topic"
        }
      }
      it "should not be ahead" do
        subject.remote_branch_exists?.should be_true
        subject.should_not be_ahead
      end
    end
  end
end

describe GitRepo, '#behind?' do
  before(:all) {
    stub_repo 'a'
    cd(tmp_prefix / 'repos/a') {
      shell "git checkout -b next"
      shell "git reset --hard origin/next^"
    }
  }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return true if there are new commits on the remote" do
    subject.remote_branch_exists?.should be_true
    subject.should be_behind
  end
  context "when the remote is merged" do
    before {
      cd(tmp_prefix / 'repos/a') {
        shell "git merge origin/next"
      }
    }
    it "should not be behind" do
      subject.remote_branch_exists?.should be_true
      subject.should_not be_behind
    end
  end
end

describe GitRepo, '#clone!' do
  before(:all) { stub_repo 'a' }
  context "for existing repos" do
    subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
    it "should raise" do
      L{
        subject.clone!('a_remote/remote.git')
      }.should raise_error(GitRepoExists, "Can't clone a_remote/remote.git to existing path #{tmp_prefix / 'repos/a'}.")
    end
  end
  context "for non-existent repos" do
    subject { Babushka::GitRepo.new(tmp_prefix / 'repos/b') }
    it "should not exist yet" do
      subject.exists?.should be_false
    end
    context "when the clone fails" do
      it "should raise" do
        L{
          subject.clone!(tmp_prefix / 'repos/a_remote/missing.git')
        }.should raise_error(GitRepoError)
      end
    end
    context "after cloning" do
      before { subject.clone! "a_remote/remote.git" }
      it "should exist now" do
        subject.exists?.should be_true
      end
      it "should have the correct remote" do
        subject.repo_shell("git remote -v").should == %Q{
origin\t#{tmp_prefix / 'repos/a_remote/remote.git'} (fetch)
origin\t#{tmp_prefix / 'repos/a_remote/remote.git'} (push)
        }.strip
      end
      it "should have the remote branch" do
        subject.repo_shell("git branch -a").should == %Q{
* master
  remotes/origin/HEAD -> origin/master
  remotes/origin/master
  remotes/origin/next
        }.strip
      end
    end
    after {
      shell "rm -rf #{tmp_prefix / 'repos/b'}"
    }
  end
end

describe GitRepo, '#branch!' do
  before(:all) { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should not already have a next branch" do
    subject.branches.should_not include('next')
  end
  context "after branching" do
    before { subject.branch! "next" }
    it "should have created a next branch" do
      subject.branches.should include('next')
    end
    it "should not be tracking anything" do
      subject.repo_shell('git config branch.next.remote').should be_nil
    end
  end
end

describe GitRepo, '#track!' do
  before(:all) { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should not already have a next branch" do
    subject.branches.should_not include('next')
  end
  context "after tracking" do
    before { subject.track! "origin/next" }
    it "should have created a next branch" do
      subject.branches.should include('next')
    end
    it "should be tracking origin/next" do
      subject.repo_shell('git config branch.next.remote').should == 'origin'
    end
  end
end

describe GitRepo, '#checkout!' do
  before(:all) {
    stub_repo 'a'
    cd(tmp_prefix / 'repos/a') {
      shell "git checkout -b next"
    }
  }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
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
    stub_repo 'a'
    cd(tmp_prefix / 'repos/a') {
      shell "echo 'more rubies' >> lib/rubies.rb"
    }
  }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should make a dirty repo clean" do
    subject.should be_dirty
    subject.reset_hard!
    subject.should be_clean
  end
end
