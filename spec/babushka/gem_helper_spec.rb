require 'spec_helper'

RSpec.describe Babushka::GemHelper do
  let(:gem_helper) { Babushka::GemHelper }
  before {
    allow(gem_helper).to receive(:versions_of).and_return([
      Babushka::VersionStr.new('0.2.11'),
      Babushka::VersionStr.new('0.2.11.3'),
      Babushka::VersionStr.new('0.3.7'),
      Babushka::VersionStr.new('0.3.9')
    ])
  }
  describe "has?" do
    it "should report installed gems correctly" do
      expect(gem_helper.has?('hammock 0.3.9')).to eq(Babushka::VersionStr.new('0.3.9'))
    end
    it "should report missing gems correctly" do
      expect(gem_helper.has?('hammock 0.3.8')).to be_nil
    end
    it "should report matching gems correctly" do
      expect(gem_helper.has?('hammock >= 0.3.10')).to be_nil
      expect(gem_helper.has?('hammock >= 0.3.9')).to eq(Babushka::VersionStr.new('0.3.9'))
      expect(gem_helper.has?('hammock >= 0.3.8')).to eq(Babushka::VersionStr.new('0.3.9'))
      expect(gem_helper.has?('hammock >= 0.3.7')).to eq(Babushka::VersionStr.new('0.3.9'))
      expect(gem_helper.has?('hammock ~> 0.2.7')).to eq(Babushka::VersionStr.new('0.2.11.3'))
      expect(gem_helper.has?('hammock ~> 0.3.7')).to eq(Babushka::VersionStr.new('0.3.9'))
    end
  end

  describe "gem_path_for" do
    let(:prefix) { '/Library/Ruby/Gems/1.8/gems' }
    before { allow(Babushka.ruby).to receive(:gem_dir).and_return(prefix) }
    it "should return the correct path" do
      expect(gem_helper.gem_path_for('hammock')).to eq(prefix / 'hammock-0.3.9')
      expect(gem_helper.gem_path_for('hammock', '0.3.9')).to eq(prefix / 'hammock-0.3.9')
      expect(gem_helper.gem_path_for('hammock', '~> 0.3.7')).to eq(prefix / 'hammock-0.3.9')
      expect(gem_helper.gem_path_for('hammock', '0.3.8')).to be_nil
    end
  end

  describe '.should_sudo?' do
    before {
      allow(Babushka.ruby).to receive_messages(
        :gem_dir => '/path/to/gems'.p,
        :bin_dir => '/path/to/bins'.p
      )
    }

    it "should return true if the bin dir is not writeable" do
      expect(File).to receive(:writable_real?).with('/path/to/bins').and_return(false)
      expect(gem_helper.should_sudo?).to be_truthy
    end

    context "when the bin dir is writable" do
      before {
        expect(File).to receive(:writable_real?).with('/path/to/bins').and_return(true)
      }
      it "should return false if the gem dir does not exist" do
        expect(Babushka.ruby.gem_dir).to receive(:exists?).and_return(false)
        expect(gem_helper.should_sudo?).to be_falsey
      end
      context "when the gem dir exists" do
        before {
          expect(Babushka.ruby.gem_dir).to receive(:exists?).and_return(true)
        }
        it "should return true if the gem dir is not writeable" do
          expect(Babushka.ruby.gem_dir).to receive(:writable_real?).and_return(false)
          expect(gem_helper.should_sudo?).to be_truthy
        end
        it "should return false if the gem dir is writeable" do
          expect(Babushka.ruby.gem_dir).to receive(:writable_real?).and_return(true)
          expect(gem_helper.should_sudo?).to be_falsey
        end
      end
    end
  end
end
