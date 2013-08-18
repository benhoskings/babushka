require 'spec_helper'

describe Cmdline, 'meet' do
  describe "with a name and uri" do
    let(:parser) {
      Cmdline::Parser.for(%w[sources -a source-name https://example.org/source-uri])
    }
    before {
      Source.should_receive(:new).with(nil, 'source-name', 'https://example.org/source-uri').and_return(
        double.tap {|d| d.should_receive(:add!) }
      )
    }
    it "should add the source" do
      parser.run
    end
  end
end
