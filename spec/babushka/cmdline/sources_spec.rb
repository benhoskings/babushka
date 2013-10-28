require 'spec_helper'

describe Babushka::Cmdline, 'meet' do
  describe "with just a name" do
    let(:parser) {
      Babushka::Cmdline::Parser.for(%w[sources -a source-name])
    }
    before {
      Babushka::Source.should_not_receive(:new)
      Babushka::LogHelpers.should_receive(:log_error)
    }
    it "should fail" do
      parser.run.should be_false
    end
  end
  describe "with a name and uri" do
    let(:parser) {
      Babushka::Cmdline::Parser.for(%w[sources -a source-name https://example.org/source-uri])
    }
    before {
      Babushka::Source.should_receive(:new).with(nil, 'source-name', 'https://example.org/source-uri').and_return(
        double.tap {|d| d.should_receive(:add!) }
      )
    }
    it "should add the source" do
      parser.run
    end
  end
end
