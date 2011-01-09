require 'spec_helper'

def stub_env_info
  GemHelper.stub!(:env_info).and_return(%q{
RubyGems Environment:
  - INSTALLATION DIRECTORY: /Library/Ruby/Gems/1.8
})
end

def stub_versions_of
  GemHelper.stub!(:versions_of).and_return([
    VersionStr.new('0.2.11'),
    VersionStr.new('0.2.11.3'),
    VersionStr.new('0.3.7'),
    VersionStr.new('0.3.9')
  ])
end

describe "has?" do
  before {
    stub_versions_of
  }
  it "should report installed gems correctly" do
    GemHelper.has?(ver('hammock', '0.3.9')).should == VersionStr.new('0.3.9')
  end
  it "should report missing gems correctly" do
    GemHelper.has?(ver('hammock', '0.3.8')).should be_nil
  end
  it "should report matching gems correctly" do
    GemHelper.has?(ver('hammock', '>= 0.3.10')).should be_nil
    GemHelper.has?(ver('hammock', '>= 0.3.9')).should == VersionStr.new('0.3.9')
    GemHelper.has?(ver('hammock', '>= 0.3.8')).should == VersionStr.new('0.3.9')
    GemHelper.has?(ver('hammock', '>= 0.3.7')).should == VersionStr.new('0.3.9')
    GemHelper.has?(ver('hammock', '~> 0.2.7')).should == VersionStr.new('0.2.11.3')
    GemHelper.has?(ver('hammock', '~> 0.3.7')).should == VersionStr.new('0.3.9')
  end
end

describe "gem_path_for" do
  before {
    stub_env_info
    stub_versions_of
    @prefix = '/Library/Ruby/Gems/1.8/gems'
  }
  it "should return the correct path" do
    GemHelper.gem_path_for('hammock').should == @prefix / 'hammock-0.3.9'
    GemHelper.gem_path_for('hammock', '0.3.9').should == @prefix / 'hammock-0.3.9'
    GemHelper.gem_path_for('hammock', '~> 0.3.7').should == @prefix / 'hammock-0.3.9'
    GemHelper.gem_path_for('hammock', '0.3.8').should be_nil
  end
end

describe Babushka::GemHelper do
  describe '.should_sudo?' do
    before :each do
      Babushka::GemHelper.stub!(
        :gem_root => '/path/to/gems'.p,
        :bin_path => '/path/to/bins'.p
      )
    end
    
    it "should return true if the bin dir is not writeable" do
      File.should_receive(:writable?).with('/path/to/bins').and_return(false)
      Babushka::GemHelper.should_sudo?.should be_true
    end

    context "when the bin dir is writable" do
      before {
        File.should_receive(:writable?).with('/path/to/bins').and_return(true)
      }
      it "should return false if the gem dir does not exist" do
        Babushka::GemHelper.gem_root.should_receive(:exists?).and_return(false)
        Babushka::GemHelper.should_sudo?.should be_false
      end
      context "when the gem dir exists" do
        before {
          Babushka::GemHelper.gem_root.should_receive(:exists?).and_return(true)
        }
        it "should return true if the gem dir is not writeable" do
          Babushka::GemHelper.gem_root.should_receive(:writable?).and_return(false)
          Babushka::GemHelper.should_sudo?.should be_true
        end
        it "should return false if the gem dir is writeable" do
          Babushka::GemHelper.gem_root.should_receive(:writable?).and_return(true)
          Babushka::GemHelper.should_sudo?.should be_false
        end
      end
    end
  end
end
