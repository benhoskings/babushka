require 'spec_helper'

describe Babushka::NpmHelper do
  let(:npm_helper) { Babushka::NpmHelper }

  describe '.should_sudo?' do
    let(:npm_prefix)            { "/some/homedir/.nodenv/versions/v0.10.28" }
    let(:npm_prefix_fancypath)  { "/some/homedir/.nodenv/versions/v0.10.28".p }

    before do
      expect(described_class).to receive(:shell).with('npm config get prefix').and_return(npm_prefix)
      allow(npm_prefix).to receive(:p).and_return(npm_prefix_fancypath)
    end

    it "should require sudo when the npm prefix dir is not writeable by the current user" do
      expect(npm_prefix_fancypath).to receive(:writable_real?).and_return(false)
      expect(npm_helper.should_sudo?).to be_truthy
    end

    it "should not require sudo when the npm prefix dir is writeable by the current user" do
      expect(npm_prefix_fancypath).to receive(:writable_real?).and_return(true)
      expect(npm_helper.should_sudo?).to be_falsey
    end
  end
end
