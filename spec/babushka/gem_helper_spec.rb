require 'spec_helper'

describe Babushka::GemHelper do
  let(:gem_helper) { Babushka::GemHelper }
  before {
    gem_helper.stub!(:versions_of).and_return([
      VersionStr.new('0.2.11'),
      VersionStr.new('0.2.11.3'),
      VersionStr.new('0.3.7'),
      VersionStr.new('0.3.9')
    ])
  }
  describe "has?" do
    it "should report installed gems correctly" do
      gem_helper.has?('hammock 0.3.9').should == VersionStr.new('0.3.9')
    end
    it "should report missing gems correctly" do
      gem_helper.has?('hammock 0.3.8').should be_nil
    end
    it "should report matching gems correctly" do
      gem_helper.has?('hammock >= 0.3.10').should be_nil
      gem_helper.has?('hammock >= 0.3.9').should == VersionStr.new('0.3.9')
      gem_helper.has?('hammock >= 0.3.8').should == VersionStr.new('0.3.9')
      gem_helper.has?('hammock >= 0.3.7').should == VersionStr.new('0.3.9')
      gem_helper.has?('hammock ~> 0.2.7').should == VersionStr.new('0.2.11.3')
      gem_helper.has?('hammock ~> 0.3.7').should == VersionStr.new('0.3.9')
    end
  end

  describe "gem_path_for" do
    let(:prefix) { '/Library/Ruby/Gems/1.8/gems' }
    before {
      gem_helper.stub!(:env_info).and_return(%q{
  RubyGems Environment:
    - INSTALLATION DIRECTORY: /Library/Ruby/Gems/1.8
  })
    }
    it "should return the correct path" do
      gem_helper.gem_path_for('hammock').should == prefix / 'hammock-0.3.9'
      gem_helper.gem_path_for('hammock', '0.3.9').should == prefix / 'hammock-0.3.9'
      gem_helper.gem_path_for('hammock', '~> 0.3.7').should == prefix / 'hammock-0.3.9'
      gem_helper.gem_path_for('hammock', '0.3.8').should be_nil
    end
  end

  describe '.should_sudo?' do
    before {
      gem_helper.stub!(
        :gem_root => '/path/to/gems'.p,
        :bin_path => '/path/to/bins'.p
      )
    }

    it "should return true if the bin dir is not writeable" do
      File.should_receive(:writable?).with('/path/to/bins').and_return(false)
      gem_helper.should_sudo?.should be_true
    end

    context "when the bin dir is writable" do
      before {
        File.should_receive(:writable?).with('/path/to/bins').and_return(true)
      }
      it "should return false if the gem dir does not exist" do
        gem_helper.gem_root.should_receive(:exists?).and_return(false)
        gem_helper.should_sudo?.should be_false
      end
      context "when the gem dir exists" do
        before {
          gem_helper.gem_root.should_receive(:exists?).and_return(true)
        }
        it "should return true if the gem dir is not writeable" do
          gem_helper.gem_root.should_receive(:writable?).and_return(false)
          gem_helper.should_sudo?.should be_true
        end
        it "should return false if the gem dir is writeable" do
          gem_helper.gem_root.should_receive(:writable?).and_return(true)
          gem_helper.should_sudo?.should be_false
        end
      end
    end
  end
end
