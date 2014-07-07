require 'spec_helper'

describe Babushka::NpmHelper do
  let(:npm_helper) { Babushka::NpmHelper }

  describe '.should_sudo?' do
    let(:npm_prefix)            { "/some/homedir/.nodenv/versions/v0.10.28" }
    let(:npm_prefix_fancypath)  { "/some/homedir/.nodenv/versions/v0.10.28".p }

    before do
      described_class.should_receive(:shell).with('npm config get prefix').and_return(npm_prefix)
      npm_prefix.stub(:p).and_return(npm_prefix_fancypath)
    end

    it "should require sudo when the npm prefix dir is not writeable by the current user" do
      npm_prefix_fancypath.should_receive(:writable_real?).and_return(false)
      npm_helper.should_sudo?.should be_true
    end

    it "should not require sudo when the npm prefix dir is writeable by the current user" do
      npm_prefix_fancypath.should_receive(:writable_real?).and_return(true)
      npm_helper.should_sudo?.should be_false
    end
  end
end
