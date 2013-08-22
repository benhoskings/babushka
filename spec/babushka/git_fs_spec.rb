require 'spec_helper'

describe Babushka::GitFS do
  let(:git_fs) { Babushka::GitFS.new }

  describe '#commit' do
    it "should commit with the given message" do
      git_fs.repo.should_receive(:init!).with((Babushka::Path.path / 'conf/git_fs_gitignore').read)
      git_fs.repo.should_receive(:repo_shell).with('git add -A .')
      git_fs.repo.should_receive(:commit!).with('dep name')
      git_fs.commit('dep name')
    end
  end

end
