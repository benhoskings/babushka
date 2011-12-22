require 'spec_helper'

describe Cmdline, 'meet' do
  describe "var parsing" do
    before {
      Base.task.should_receive(:process).with(
        %w[git],
        {'version' => '1.7.7', 'source' => 'http://git.org/git.tgz'}
      )
    }
    it "should recognise vars" do
      Cmdline::Parser.for(%w[git version=1.7.7 source=http://git.org/git.tgz]).run
    end
  end
end
