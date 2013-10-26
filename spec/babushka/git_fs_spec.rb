require 'spec_helper'

describe Babushka::GitFS do
  let(:git_fs) { Babushka::GitFS }

  describe '#init' do
    context "when the repo doesn't exist" do
      it "should init, and commit the current system" do
        git_fs.repo.stub(:exists?) { false }
        git_fs.repo.should_receive(:init!)
        git_fs.init
      end
    end
    context "when the repo already exists" do
      it "should do nothing" do
        git_fs.repo.stub(:exists?) { true }
        git_fs.repo.should_not_receive(:init)
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
