require 'spec_helper'

describe Babushka::Cmdline, 'meet' do
  describe "with just a name" do
    let(:parser) {
      Babushka::Cmdline::Parser.for(%w[sources -a source-name])
    }
    before {
      expect(Babushka::Source).not_to receive(:new)
      expect(Babushka::LogHelpers).to receive(:log_error)
    }
    it "should fail" do
      expect(parser.run).to be_falsey
    end
  end
  describe "with a name and uri" do
    let(:parser) {
      Babushka::Cmdline::Parser.for(%w[sources -a source-name https://example.org/source-uri])
    }
    before {
      expect(Babushka::Source).to receive(:new).with(nil, 'source-name', 'https://example.org/source-uri').and_return(
        double.tap {|d| expect(d).to receive(:add!) }
      )
    }
    it "should add the source" do
      parser.run
    end
  end
end
