require 'spec_support'

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
    stub_versions_of
    @prefix = `gem env gemdir`.chomp / 'gems'
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
        :gem_root => '/path/to/gems',
        :bin_root => '/path/to/bins'
      )
    end
    
    it "should return true if the bin dir is not writeable" do
      File.should_receive(:writable?).with('/path/to/gems').and_return(true)
      File.should_receive(:writable?).with('/path/to/bins').and_return(false)
      
      Babushka::GemHelper.should_sudo?.should be_true
    end
    
    it "should return true if the gem dir is not writeable" do
      File.should_receive(:writable?).with('/path/to/gems').and_return(false)
      # File.should_receive(:writable?).with('/path/to/bins').and_return(true)
      
      Babushka::GemHelper.should_sudo?.should be_true
    end
    
    it "should return false if both gem and bin dirs are writeable" do
      File.should_receive(:writable?).with('/path/to/gems').and_return(true)
      File.should_receive(:writable?).with('/path/to/bins').and_return(true)
      
      Babushka::GemHelper.should_sudo?.should be_false
    end
  end
end
