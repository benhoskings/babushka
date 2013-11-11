require 'spec_helper'

describe Babushka::GitFS do
  let(:git_fs) { Babushka::GitFS }

  describe 'repo' do
    it "should run destrucive commands as the repo owner" do
      git_fs.repo.run_as_owner?.should be_true
    end
  end

  describe '#snapshotting_with' do
    let(:blk) { lambda {} }
    context "when snapshotting is enabled" do
      before {
        Babushka::Base.task.stub(:opt).with(:git_fs) { true }
      }
      it "should init, run, and commit on success" do
        git_fs.should_receive(:init)
        blk.should_receive(:call) { true }
        git_fs.should_receive(:commit).with('A message')
        # I would pass the block directly here (and below (*)):
        #   git_fs.snapshotting_with('A message', &blk)
        # But doing so on ruby 1.8 prevents rspec from seeing blk.call in places
        # where blk was passed as a block (i.e. inside #snapshotting_with).
        git_fs.snapshotting_with('A message') { blk.call }
      end
      it "should init, run, and not commit on failure" do
        git_fs.should_receive(:init)
        blk.should_receive(:call) { false }
        git_fs.should_not_receive(:commit)
        git_fs.snapshotting_with('A message') { blk.call } # (*)
      end
    end
    context "when snapshotting is enabled" do
      before {
        Babushka::Base.task.stub(:opt).with(:git_fs) { false }
      }
      it "should just call the block" do
        git_fs.should_not_receive(:init)
        blk.should_receive(:call)
        git_fs.should_not_receive(:commit).with('A message')
        git_fs.snapshotting_with('A message') { blk.call } # (*)
      end
    end
  end

  describe '#init' do
    context "when the repo doesn't exist" do
      it "should init, and commit the current system" do
        git_fs.repo.stub(:exists?) { false }
        git_fs.repo.should_receive(:init!)
        git_fs.should_receive(:commit).with("Add the base system.")
        git_fs.init
      end
    end
    context "when the repo already exists" do
      it "should do nothing" do
        git_fs.repo.stub(:exists?) { true }
        git_fs.repo.should_not_receive(:init)
        git_fs.should_not_receive(:commit)
        git_fs.init
      end
    end
  end

  describe '#commit' do
    it "should commit with the given message" do
      git_fs.repo.should_receive(:repo_shell_as_owner).with('git add -A .')
      git_fs.repo.should_receive(:commit!).with('dep name')
      git_fs.commit('dep name')
    end
  end

end
