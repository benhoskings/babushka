require 'spec/spec_support'

describe "description" do
  before {
    GemHelper.stub!(:versions_of).and_return([
      VersionStr.new('0.2.11'),
      VersionStr.new('0.2.11.3'),
      VersionStr.new('0.3.7'),
      VersionStr.new('0.3.9')
    ])
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
