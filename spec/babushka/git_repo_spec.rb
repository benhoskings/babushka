require 'spec_helper'

def stub_commitless_repo name
  (tmp_prefix / 'repos' / name).rm
  Babushka::PathHelpers.cd tmp_prefix / 'repos' / name, :create => true do
    Babushka::ShellHelpers.shell "git init"
  end
end

def stub_repo name, &block
  (tmp_prefix / 'repos' / "#{name}_remote").rm
  Babushka::PathHelpers.cd tmp_prefix / 'repos' / "#{name}_remote", :create => true do
    Babushka::ShellHelpers.shell "tar -zxvf #{File.dirname(__FILE__) / '../repos/remote.git.tgz'}"
  end

  (tmp_prefix / 'repos' / name).rm
  Babushka::PathHelpers.cd tmp_prefix / 'repos' do |path|
    Babushka::ShellHelpers.shell "git clone #{name}_remote/remote.git #{name}"
    yield(Babushka::GitRepo.new(path / name)) if block_given?
  end
end

def repo_context name, &block
  Babushka::PathHelpers.cd(tmp_prefix / 'repos'/ name, &block)
end

describe Babushka::GitRepo, 'creation' do
  before(:all) { stub_repo 'a' }
  it "should return nil on nonexistent paths" do
    expect(Babushka::GitRepo.new(tmp_prefix / 'repos/missing').root).to eq(nil)
  end
  it "should return nil on non-repo paths" do
    expect(Babushka::GitRepo.new(tmp_prefix / 'repos').root).to eq(nil)
  end
  it "should recognise the repo path as a string" do
    expect(Babushka::GitRepo.new((tmp_prefix / 'repos/a').to_s).root).to eq(tmp_prefix / 'repos/a')
  end
  it "should recognise the repo path as a Fancypath" do
    expect(Babushka::GitRepo.new(tmp_prefix / 'repos/a').root).to eq(tmp_prefix / 'repos/a')
  end
  it "should find the parent when called on the subdir" do
    expect(Babushka::GitRepo.new(tmp_prefix / 'repos/a/lib').root).to eq(tmp_prefix / 'repos/a')
  end
  it "should find the git dir within the repo" do
    expect(Babushka::GitRepo.new(tmp_prefix / 'repos/a').git_dir).to eq(tmp_prefix / 'repos/a/.git')
    expect(Babushka::GitRepo.new(tmp_prefix / 'repos/a/lib').git_dir).to eq(tmp_prefix / 'repos/a/.git')
  end
  it "should store path as a Fancypath" do
    expect(Babushka::GitRepo.new((tmp_prefix / 'repos/a').to_s).path).to be_an_instance_of(Fancypath)
    expect(Babushka::GitRepo.new(tmp_prefix / 'repos/a').path).to be_an_instance_of(Fancypath)
  end
  it "should return the repo path as a Fancypath" do
    expect(Babushka::GitRepo.new((tmp_prefix / 'repos/a').to_s).root).to be_an_instance_of(Fancypath)
    expect(Babushka::GitRepo.new(tmp_prefix / 'repos/a').root).to be_an_instance_of(Fancypath)
  end
  describe "options" do
    it "should accept :run_as_owner" do
      expect(Babushka::GitRepo.new(tmp_prefix / 'repos/a', :run_as_owner => true).run_as_owner?).to be_truthy
    end
  end
end

describe Babushka::GitRepo, 'without a dir' do
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/missing') }
  it "should not exist" do
    expect(subject.exists?).to be_falsey
  end
  [:clean?, :dirty?, :current_branch, :current_head, :remote_branch_exists?, :ahead?].each {|method|
    it "should raise on #{method}" do
      expect(L{ subject.send(method) }).to raise_error(Babushka::GitRepoError, "There is no repo at #{tmp_prefix / 'repos/missing'}.")
    end
  }
  context "with lazy eval" do
    subject { Babushka::GitRepo.new(tmp_prefix / 'repos/lazy_dir') }
    it "should fail before the repo is created, but work afterwards" do
      expect(subject.exists?).to be_falsey
      expect(L{ subject.clean? }).to raise_error(Babushka::GitRepoError, "There is no repo at #{tmp_prefix / 'repos/lazy_dir'}.")
      stub_repo 'lazy_dir'
      expect(subject.exists?).to be_truthy
      expect(subject).to be_clean
    end
  end
end

describe Babushka::GitRepo, 'without a repo' do
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/empty') }
  before { (tmp_prefix / 'repos/empty').mkdir }

  it "should not exist" do
    expect(subject.exists?).to be_falsey
  end
  [:clean?, :dirty?, :current_branch, :current_head, :remote_branch_exists?, :ahead?].each {|method|
    it "should raise on #{method}" do
      expect(L{ subject.send(method) }).to raise_error(Babushka::GitRepoError, "There is no repo at #{tmp_prefix / 'repos/empty'}.")
    end
  }
  context "with lazy eval" do
    subject { Babushka::GitRepo.new(tmp_prefix / 'repos/lazy_repo') }
    it "should fail before the repo is created, but work afterwards" do
      expect(subject.exists?).to be_falsey
      expect(L{ subject.clean? }).to raise_error(Babushka::GitRepoError, "There is no repo at #{tmp_prefix / 'repos/lazy_repo'}.")
      stub_repo 'lazy_repo'
      expect(subject.exists?).to be_truthy
      expect(subject).to be_clean
    end
  end
end

describe Babushka::GitRepo, "with a repo" do
  before(:all) { stub_repo 'a' }
  it "should exist with string path" do
    expect(Babushka::GitRepo.new((tmp_prefix / 'repos/a').to_s).exists?).to be_truthy
  end
  it "should exist with Fancypath path" do
    expect(Babushka::GitRepo.new(tmp_prefix / 'repos/a').exists?).to be_truthy
  end
end

describe 'shelling' do
  before(:all) { stub_repo 'a' }
  let(:repo) { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }

  describe "#repo_shell" do
    it "should raise an error when the repo doesn't exist" do
      allow(repo).to receive(:exists?) { false }
      expect { repo.repo_shell('true') }.to raise_error(Babushka::GitRepoError, "There is no repo at #{tmp_prefix / 'repos/a'}.")
    end
    it "should run the given command inside the repo" do
      allow(repo).to receive(:exists?) { true }
      expect(repo).to receive(:shell).with('true', :cd => (tmp_prefix / 'repos/a'), :an => 'option')
      repo.repo_shell('true', :an => 'option')
    end
  end

  describe "#repo_shell?" do
    it "should raise an error when the repo doesn't exist" do
      allow(repo).to receive(:exists?) { false }
      expect { repo.repo_shell?('true') }.to raise_error(Babushka::GitRepoError, "There is no repo at #{tmp_prefix / 'repos/a'}.")
    end
    it "should run the given command inside the repo" do
      allow(repo).to receive(:exists?) { true }
      expect(repo).to receive(:shell?).with('true', :cd => (tmp_prefix / 'repos/a'), :an => 'option')
      repo.repo_shell?('true', :an => 'option')
    end
  end

  describe "#repo_shell_as_owner" do
    context "when run_as_owner is set" do
      it "should run the given command as the repo owner" do
        allow(repo).to receive(:run_as_owner?) { true }
        allow(repo.root).to receive(:owner) { 'bob' }
        expect(repo).to receive(:repo_shell).with('true', :as => 'bob')
        repo.repo_shell_as_owner('true')
      end
    end
    context "when run_as_owner is not set" do
      it "should run the given command as the current user" do
        allow(repo.root).to receive(:owner) { 'bob' }
        expect(repo).to receive(:repo_shell).with('true', {})
        repo.repo_shell_as_owner('true')
      end
    end
  end
end

describe Babushka::GitRepo, '#clean? / #dirty?' do
  context "on commitless repos" do
    before(:all) { stub_commitless_repo 'a' }
    subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
    it "should be clean" do
      expect(subject).to be_clean
      expect(subject).not_to be_dirty
    end
  end
  context "on normal repos" do
    before(:all) { stub_repo 'a' }
    subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
    it "should be clean" do
      expect(subject).to be_clean
      expect(subject).not_to be_dirty
    end
    context "when there are changes" do
      before {
        Babushka::PathHelpers.cd(tmp_prefix / 'repos/a') { Babushka::ShellHelpers.shell "echo dirt >> content.txt" }
      }
      it "should be dirty" do
        expect(subject).not_to be_clean
        expect(subject).to be_dirty
      end
      context "when the changes are staged" do
        before {
          Babushka::PathHelpers.cd(tmp_prefix / 'repos/a') { Babushka::ShellHelpers.shell "git add --update ." }
        }
        it "should be dirty" do
          expect(subject).not_to be_clean
          expect(subject).to be_dirty
        end
      end
    end
  end
end

describe Babushka::GitRepo, '#include?' do
  before(:all) { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return true for valid commits" do
    expect(subject.include?('20758f2d9d696c51ac83a0fd36626d421057b24d')).to be_truthy
    expect(subject.include?('20758f2')).to be_truthy
  end
  it "should return false for nonexistent commits" do
    expect(subject.include?('20758f2d9d696c51ac83a0fd36626d421057b24e')).to be_falsey
    expect(subject.include?('20758f3')).to be_falsey
  end
end

describe Babushka::GitRepo, '#branches' do
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  context "on a repo with commits" do
    before(:all) { stub_repo 'a' }
    it "should return the only branch in a list" do
      expect(subject.branches).to eq(['master'])
    end
    context "after creating another branch" do
      before(:all) {
        repo_context('a') { Babushka::ShellHelpers.shell "git checkout -b next" }
      }
      it "should return both branches" do
        expect(subject.branches).to eq(['master', 'next'])
      end
      context "after changing back to master" do
        before {
          repo_context('a') { Babushka::ShellHelpers.shell "git checkout master" }
        }
        it "should return both branches" do
          expect(subject.branches).to eq(['master', 'next'])
        end
      end
    end
  end
  context "on a repo with no commits" do
    before { stub_commitless_repo 'a' }
    it "should return no branches" do
      expect(subject.branches).to eq([])
    end
  end
end

describe Babushka::GitRepo, '#all_branches' do
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  context "on a repo with commits" do
    before(:all) { stub_repo 'a' }
    it "should return the only branch in a list" do
      expect(subject.all_branches).to eq(["master", "origin/master", "origin/next"])
    end
    it "should not return tags" do
      subject.repo_shell('git tag tagged_ref')
      expect(subject.all_branches.grep(/tagged_ref/)).to be_empty
    end
    context "after creating another branch" do
      before(:all) {
        repo_context('a') { Babushka::ShellHelpers.shell "git checkout -b next" }
      }
      it "should return both branches" do
        expect(subject.all_branches).to eq(["master", "next", "origin/master", "origin/next"])
      end
      context "after changing back to master" do
        before {
          repo_context('a') { Babushka::ShellHelpers.shell "git checkout master" }
        }
        it "should return both branches" do
          expect(subject.all_branches).to eq(["master", "next", "origin/master", "origin/next"])
        end
      end
    end
  end
  context "on a repo with no commits" do
    before { stub_commitless_repo 'a' }
    it "should return no branches" do
      expect(subject.all_branches).to eq([])
    end
  end
end

describe Babushka::GitRepo, '#current_branch' do
  before(:all) { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return 'master'" do
    expect(subject.current_branch).to eq('master')
  end
  context "after creating another branch" do
    before(:all) {
      repo_context('a') { Babushka::ShellHelpers.shell "git checkout -b next" }
    }
    it "should return 'next'" do
      expect(subject.current_branch).to eq('next')
    end
    context "after changing back to master" do
      before {
        repo_context('a') { Babushka::ShellHelpers.shell "git checkout master" }
      }
      it "should return 'next'" do
        expect(subject.current_branch).to eq('master')
      end
    end
    context "after detaching" do
      before {
        repo_context('a') { Babushka::ShellHelpers.shell "git checkout master^0" }
      }
      it "should return a SHA" do
        expect(subject.current_branch).to match(/^\w{40}$/)
      end
    end
  end
end

describe Babushka::GitRepo, '#current_remote_branch' do
  before(:all) { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return the namespaced remote branch" do
    expect(subject.current_remote_branch).to eq('origin/master')
  end
  context "after switching to a custom branch" do
    before {
      subject.repo_shell('git checkout -b next')
      subject.repo_shell('git config branch.next.remote upstream')
    }
    it "should return 'origin' when no remote is set" do
      expect(subject.current_remote_branch).to eq('upstream/next')
    end
  end
end

describe Babushka::GitRepo, '#current_head' do
  before { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return a short commit id" do
    expect(subject.current_head).to match(/^[0-9a-f]{7}$/)
  end
end

describe Babushka::GitRepo, '#current_full_head' do
  before { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return a full commit id" do
    expect(subject.current_full_head).to match(/^[0-9a-f]{40}$/)
  end
end

describe Babushka::GitRepo, '#resolve' do
  before { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return a short commit id" do
    expect(subject.resolve('master')).to match(/^[0-9a-f]{7}$/)
  end
end

describe Babushka::GitRepo, '#resolve_full' do
  before { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return a full commit id" do
    expect(subject.resolve_full('master')).to match(/^[0-9a-f]{40}$/)
  end
end

describe Babushka::GitRepo, '#remote_for' do
  before(:all) {
    stub_repo 'a' do |repo|
      repo.repo_shell('git config branch.next.remote upstream')
    end
  }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return the remote when it's set in the config" do
    expect(subject.remote_for('next')).to eq('upstream')
  end
  it "should return 'origin' when no remote is set" do
    expect(subject.remote_for('lolbranch')).to eq('origin')
  end
end

describe Babushka::GitRepo, '#ahead?' do
  before(:all) {
    stub_repo 'a'
    Babushka::PathHelpers.cd(tmp_prefix / 'repos/a') {
      Babushka::ShellHelpers.shell "git checkout -b topic"
    }
  }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should have a local topic branch" do
    expect(subject.current_branch).to eq('topic')
  end
  it "should return true if the current branch has no remote" do
    expect(subject.remote_branch_exists?).to be_falsey
    expect(subject).to be_ahead
  end
  context "when remote branch exists" do
    before(:all) {
      Babushka::PathHelpers.cd(tmp_prefix / 'repos/a') {
        Babushka::ShellHelpers.shell "git push origin topic"
        Babushka::ShellHelpers.shell 'echo "Ch-ch-ch-changes" >> content.txt'
        Babushka::ShellHelpers.shell 'git commit -a -m "Changes!"'
      }
    }
    it "should have a local topic branch" do
      expect(subject.current_branch).to eq('topic')
    end
    it "should return true if there are unpushed commits on the current branch" do
      expect(subject.remote_branch_exists?).to be_truthy
      expect(subject).to be_ahead
    end
    context "when the branch is fully pushed" do
      before {
        Babushka::PathHelpers.cd(tmp_prefix / 'repos/a') {
          Babushka::ShellHelpers.shell "git push origin topic"
        }
      }
      it "should not be ahead" do
        expect(subject.remote_branch_exists?).to be_truthy
        expect(subject).not_to be_ahead
      end
      context "when the remote doesn't exist" do
        before {
          subject.repo_shell('git config branch.topic.remote upstream')
        }
        it "should be ahead" do
          expect(subject.remote_branch_exists?).to be_falsey
          expect(subject).to be_ahead
        end
      end
    end
  end
end

describe Babushka::GitRepo, '#behind?' do
  before(:all) {
    stub_repo 'a'
    Babushka::PathHelpers.cd(tmp_prefix / 'repos/a') {
      Babushka::ShellHelpers.shell "git checkout -b next"
      Babushka::ShellHelpers.shell "git reset --hard origin/next^"
    }
  }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should return true if there are new commits on the remote" do
    expect(subject.remote_branch_exists?).to be_truthy
    expect(subject).to be_behind
  end
  context "when the remote is merged" do
    before {
      Babushka::PathHelpers.cd(tmp_prefix / 'repos/a') {
        Babushka::ShellHelpers.shell "git merge origin/next"
      }
    }
    it "should not be behind" do
      expect(subject.remote_branch_exists?).to be_truthy
      expect(subject).not_to be_behind
    end
    context "when the remote doesn't exist" do
      before {
        subject.repo_shell('git config branch.next.remote upstream')
      }
      it "should be ahead" do
        expect(subject.remote_branch_exists?).to be_falsey
        expect(subject).to be_ahead
      end
    end
  end
end

describe Babushka::GitRepo, '#init!' do
  context "when the repo doesn't exist" do
    let(:repo) { Babushka::GitRepo.new(tmp_prefix / 'repos/uninited') }
    it "should init the repo" do
      expect { repo.init! }.to change(repo, :exists?).from(false).to(true)
    end
    it "should add an initial commit" do
      repo.init!
      expect(repo.repo_shell('git rev-list HEAD | wc -l').strip.to_i).to eq(1)
    end
    context "when no gitignore is supplied" do
      it "should add an empty gitignore" do
        repo.init!
        expect(repo.repo_shell('git show HEAD:.gitignore')).to eq('')
      end
    end
    context "when a gitignore is supplied" do
      it "should use that gitignore" do
        repo.init!('log/')
        expect(repo.repo_shell('git show HEAD:.gitignore')).to eq('log/')
      end
    end
    after { repo.root.rm }
  end
  context "when a repo already exists" do
    before(:all) { stub_repo 'a' }
    let(:repo) { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
    it "should not re-init the repo" do
      expect(repo).not_to receive(:shell)
      repo.init!
    end
  end
end

describe Babushka::GitRepo, '#clone!' do
  before(:all) { stub_repo 'a' }
  context "for existing repos" do
    subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
    it "should raise" do
      expect(L{
        subject.clone!('a_remote/remote.git')
      }).to raise_error(Babushka::GitRepoExists, "Can't clone a_remote/remote.git to existing path #{tmp_prefix / 'repos/a'}.")
    end
  end
  context "for non-existent repos" do
    subject { Babushka::GitRepo.new(tmp_prefix / 'repos/b') }
    it "should not exist yet" do
      expect(subject.exists?).to be_falsey
    end
    context "when the clone fails" do
      it "should raise" do
        expect(L{
          subject.clone!(tmp_prefix / 'repos/a_remote/missing.git')
        }).to raise_error(Babushka::GitRepoError)
      end
    end
    context "after cloning" do
      before { subject.clone! "a_remote/remote.git" }
      it "should exist now" do
        expect(subject.exists?).to be_truthy
      end
      it "should have the correct remote" do
        expect(subject.repo_shell("git remote -v")).to eq(%Q{
origin\t#{tmp_prefix / 'repos/a_remote/remote.git'} (fetch)
origin\t#{tmp_prefix / 'repos/a_remote/remote.git'} (push)
        }.strip)
      end
      it "should have the remote branch" do
        expect(subject.repo_shell("git branch -a")).to eq(%Q{
* master
  remotes/origin/HEAD -> origin/master
  remotes/origin/master
  remotes/origin/next
        }.strip)
      end
    end
    after {
      Babushka::ShellHelpers.shell "rm -rf #{tmp_prefix / 'repos/b'}"
    }
  end
end

describe Babushka::GitRepo, '#commit!' do
  before(:all) { stub_repo 'a' }
  let(:repo) { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should run using repo_shell_as_owner" do
    expect(repo).to receive(:repo_shell_as_owner)
    repo.commit!('from specs')
  end
  it "should shell out to git" do
    expect(repo).to receive(:shell).with('git', 'commit', '-m', 'from specs', :cd => repo.root)
    repo.commit!('from specs')
  end
  it "should create a commit" do
    (repo.root / 'file').write('contents')
    repo.repo_shell('git add -A .')
    expect { repo.commit!('from specs') }.to change { repo.repo_shell('git rev-list HEAD | wc -l').strip.to_i }.by(1)
  end
end

describe Babushka::GitRepo, '#branch!' do
  before(:all) { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should run using repo_shell_as_owner" do
    expect(subject).to receive(:repo_shell_as_owner)
    subject.branch!('next')
  end
  it "should not already have a next branch" do
    expect(subject.branches).not_to include('next')
  end
  context "after branching" do
    before(:all) { Babushka::GitRepo.new(tmp_prefix / 'repos/a').branch! "next" }
    it "should have created the branch" do
      expect(subject.branches).to include('next')
    end
    it "should have pointed the branch at HEAD" do
      expect(subject.resolve('next')).to eq(subject.resolve("master"))
    end
    it "should not be tracking anything" do
      expect(subject.repo_shell('git config branch.next.remote')).to be_nil
    end
    it "should not have checked out the branch" do
      expect(subject.current_branch).to eq("master")
    end
  end
  context "after branching to a ref" do
    before(:all) {
      Babushka::PathHelpers.cd(tmp_prefix / 'repos/a') {
        Babushka::ShellHelpers.shell 'echo "Ch-ch-ch-changes" >> content.txt'
        Babushka::ShellHelpers.shell 'git commit -a -m "Changes!"'
      }
      Babushka::GitRepo.new(tmp_prefix / 'repos/a').branch! "another", "master~"
    }
    it "should have created the branch" do
      expect(subject.branches).to include('another')
    end
    it "should have pointed the branch at the right ref" do
      expect(subject.resolve('another')).to eq(subject.resolve("master~"))
    end
    it "should not be tracking anything" do
      expect(subject.repo_shell('git config branch.another.remote')).to be_nil
    end
    it "should not have checked out the branch" do
      expect(subject.current_branch).to eq("master")
    end
  end
end

describe Babushka::GitRepo, '#track!' do
  before(:all) { stub_repo 'a' }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should run using repo_shell_as_owner" do
    expect(subject).to receive(:repo_shell_as_owner)
    subject.track!('origin/next')
  end
  it "should not already have a next branch" do
    expect(subject.branches).not_to include('next')
  end
  context "after tracking" do
    before(:all) { Babushka::GitRepo.new(tmp_prefix / 'repos/a').track! "origin/next" }
    it "should have created a next branch" do
      expect(subject.branches).to include('next')
    end
    it "should be tracking origin/next" do
      expect(subject.repo_shell('git config branch.next.remote')).to eq('origin')
    end
  end
end

describe Babushka::GitRepo, '#checkout!' do
  before(:all) {
    stub_repo 'a'
    Babushka::PathHelpers.cd(tmp_prefix / 'repos/a') {
      Babushka::ShellHelpers.shell "git checkout -b next"
    }
  }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should run using repo_shell_as_owner" do
    expect(subject).to receive(:repo_shell_as_owner)
    subject.checkout!('master')
  end
  describe "checking out a branch" do
    it "should already have a next branch" do
      expect(subject.branches).to match_array(%w[master next])
      expect(subject.current_branch).to eq('next')
    end
    context "after checking out" do
      before {
        subject.checkout! "master"
      }
      it "should be on the master branch now" do
        expect(subject.current_branch).to eq('master')
      end
    end
  end
  describe "checking out a ref" do
    before {
      subject.checkout! 'origin/next~'
    }
    it "should detach the HEAD" do
      expect(subject.branches).to match_array(%w[master next])
      expect(subject.current_branch).to match(/^[0-9a-f]{40}$/)
    end
  end
end

describe Babushka::GitRepo, '#detach!' do
  before(:all) {
    stub_repo 'a'
  }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should run using repo_shell_as_owner" do
    expect(subject).to receive(:repo_shell_as_owner)
    subject.detach!
  end
  it "should detach to HEAD when no ref is supplied" do
    subject.detach!
    expect(subject.current_branch).to match(/^[0-9a-f]{40}$/)
    expect(subject.current_branch.starts_with?(subject.resolve('master'))).to be_truthy
  end
  it "should detach the HEAD when a ref is supplied" do
    subject.detach! 'origin/next'
    expect(subject.current_branch).to match(/^[0-9a-f]{40}$/)
    expect(subject.current_branch.starts_with?(subject.resolve('origin/next'))).to be_truthy
  end
  it "should detach the HEAD when a branch is supplied" do
    subject.detach! "master"
    expect(subject.current_branch).to match(/^[0-9a-f]{40}$/)
    expect(subject.current_branch.starts_with?(subject.resolve('master'))).to be_truthy
  end
end

describe Babushka::GitRepo, '#reset_hard!' do
  before {
    stub_repo 'a'
    Babushka::PathHelpers.cd(tmp_prefix / 'repos/a') {
      Babushka::ShellHelpers.shell "echo 'more rubies' >> lib/rubies.rb"
    }
  }
  subject { Babushka::GitRepo.new(tmp_prefix / 'repos/a') }
  it "should run using repo_shell_as_owner" do
    expect(subject).to receive(:repo_shell_as_owner)
    subject.reset_hard!
  end
  it "should make a dirty repo clean" do
    expect(subject).to be_dirty
    subject.reset_hard!
    expect(subject).to be_clean
  end
end
