require 'spec_helper'

describe Babushka::SSH do
  let(:ssh) {
    Babushka::SSH.new('user@host')
  }
  describe '#shell' do
    it "should run remote commands" do
      ShellHelpers.should_receive(:shell).with("ssh", "-A", "user@host", "'ls'", :log => true)
      ssh.shell('ls')
    end
  end
end
