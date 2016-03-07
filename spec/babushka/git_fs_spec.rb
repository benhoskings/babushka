require 'spec_helper'

describe Babushka::GitFS do
  let(:git_fs) { Babushka::GitFS }

  describe 'repo' do
    it "should run destrucive commands as the repo owner" do
      expect(git_fs.repo.run_as_owner?).to be_truthy
    end
  end

  describe '#snapshotting_with' do
    let(:blk) { lambda {} }
    context "when snapshotting is enabled" do
      before {
        allow(Babushka::Base.task).to receive(:opt).with(:git_fs) { true }
      }
      it "should init, run, and commit on success" do
        expect(git_fs).to receive(:init)
        expect(blk).to receive(:call) { true }
        expect(git_fs).to receive(:commit).with('A message')
        # I would pass the block directly here (and below (*)):
        #   git_fs.snapshotting_with('A message', &blk)
        # But doing so on ruby 1.8 prevents rspec from seeing blk.call in places
        # where blk was passed as a block (i.e. inside #snapshotting_with).
        git_fs.snapshotting_with('A message') { blk.call }
      end
      it "should init, run, and not commit on failure" do
        expect(git_fs).to receive(:init)
        expect(blk).to receive(:call) { false }
        expect(git_fs).not_to receive(:commit)
        git_fs.snapshotting_with('A message') { blk.call } # (*)
      end
    end
    context "when snapshotting is enabled" do
      before {
        allow(Babushka::Base.task).to receive(:opt).with(:git_fs) { false }
      }
      it "should just call the block" do
        expect(git_fs).not_to receive(:init)
        expect(blk).to receive(:call)
        expect(git_fs).not_to receive(:commit).with('A message')
        git_fs.snapshotting_with('A message') { blk.call } # (*)
      end
    end
  end

  describe '#init' do
    context "when the repo doesn't exist" do
      it "should configure name, init, and commit the current system" do
        expect(git_fs).to receive(:set_name_and_email)
        allow(git_fs.repo).to receive(:exists?) { false }
        expect(git_fs.repo).to receive(:init!)
        expect(git_fs).to receive(:commit).with("Add the base system.")
        git_fs.init
      end
    end
    context "when the repo already exists" do
      it "should do nothing" do
        expect(git_fs).not_to receive(:set_name_and_email)
        allow(git_fs.repo).to receive(:exists?) { true }
        expect(git_fs.repo).not_to receive(:init)
        expect(git_fs).not_to receive(:commit)
        git_fs.init
      end
    end
  end

  describe '#commit' do
    it "should commit with the given message" do
      expect(git_fs.repo).to receive(:repo_shell_as_owner).with('git add -A .')
      expect(git_fs.repo).to receive(:commit!).with('dep name')
      git_fs.commit('dep name')
    end
  end

  describe '#set_name_and_email' do
    context "when neither the name nor the email are set" do
      before {
        allow(Babushka::ShellHelpers).to receive(:shell?).with("git config --global user.name") { false }
        allow(git_fs.repo).to receive(:owner) { 'root' }
      }
      it "should set the name and email" do
        expect(Babushka::ShellHelpers).to receive(:shell).with("git config --global user.name babushka", :as => 'root')
        expect(Babushka::ShellHelpers).to receive(:shell).with("git config --global user.email hello@babushka.me", :as => 'root')
        git_fs.set_name_and_email
      end
    end
    context "when at least one of name and email is not set" do
      before {
        allow(Babushka::ShellHelpers).to receive(:shell?).with("git config --global user.name") { true }
        allow(Babushka::ShellHelpers).to receive(:shell?).with("git config --global user.email") { false }
        allow(git_fs.repo).to receive(:owner) { 'root' }
      }
      it "should set the name and email" do
        expect(Babushka::ShellHelpers).to receive(:shell).with("git config --global user.name babushka", :as => 'root')
        expect(Babushka::ShellHelpers).to receive(:shell).with("git config --global user.email hello@babushka.me", :as => 'root')
        git_fs.set_name_and_email
      end
    end
    context "when name and email are both set" do
      before {
        allow(Babushka::ShellHelpers).to receive(:shell?).with("git config --global user.name") { true }
        allow(Babushka::ShellHelpers).to receive(:shell?).with("git config --global user.email") { true }
        allow(git_fs.repo).to receive(:owner) { 'root' }
      }
      it "should set the name and email" do
        expect(Babushka::ShellHelpers).not_to receive(:shell)
        git_fs.set_name_and_email
      end
    end
  end

end
