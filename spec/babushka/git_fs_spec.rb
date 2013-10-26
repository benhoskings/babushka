require 'spec_helper'

describe Babushka::GitFS do
  let(:git_fs) { Babushka::GitFS }

  describe '#snapshotting_with' do
    let(:blk) { ->{} }
    context "when snapshotting is enabled" do
      before {
        Base.task.stub(:opt).with(:git_fs) { true }
      }
      it "should init, run, and commit on success" do
        git_fs.should_receive(:init)
        blk.should_receive(:call) { true }
        git_fs.should_receive(:commit).with('A message')
        git_fs.snapshotting_with('A message', &blk)
      end
      it "should init, run, and not commit on failure" do
        git_fs.should_receive(:init)
        blk.should_receive(:call) { false }
        git_fs.should_not_receive(:commit)
        git_fs.snapshotting_with('A message', &blk)
      end
    end
    context "when snapshotting is enabled" do
      before {
        Base.task.stub(:opt).with(:git_fs) { false }
      }
      it "should just call the block" do
        git_fs.should_not_receive(:init)
        blk.should_receive(:call)
        git_fs.should_not_receive(:commit).with('A message')
        git_fs.snapshotting_with('A message', &blk)
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
      git_fs.repo.should_receive(:repo_shell).with('git add -A .')
      git_fs.repo.should_receive(:commit!).with('dep name')
      git_fs.commit('dep name')
    end
  end

end
