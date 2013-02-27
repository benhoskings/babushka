require 'spec_helper'

describe Cmdline, 'meet' do
  describe "argument parsing" do
    let(:parser) {
      Cmdline::Parser.for(%w[git version=1.7.7 source=http://git.org/git.tgz])
    }
    before {
      Base.task.should_receive(:process).with(
        %w[git],
        {'version' => '1.7.7', 'source' => 'http://git.org/git.tgz'},
        parser
      )
    }
    it "should recognise args" do
      parser.run
    end
  end
end
