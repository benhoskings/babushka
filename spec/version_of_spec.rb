require 'spec/spec_support'

describe "creation" do
  it "should store name" do
    ver('ruby').name.should == 'ruby'
  end
  it "should accept versions, optionally" do
    ver('ruby').version.should == nil
    ver('ruby', '1.8').version.to_s.should == '1.8'
    ver('ruby', '1.8'.to_version).version.to_s.should == '1.8'
  end
end

describe "comparisons" do
  it "should compare to versionless strings" do
    ver('ruby'       ).should     == 'ruby'
    ver('ruby', '1.8').should_not == 'ruby'
  end
  it "should compare to versioned strings" do
    ver('ruby'       ).should_not == 'ruby-1.8'
    ver('ruby', '1.8').should     == 'ruby-1.8'
    ver('ruby', '1.8').should_not == 'ruby-1.9'
  end
  it "should compare to versionless VersionOfs" do
    ver('ruby'       ).should     == ver('ruby')
    ver('ruby', '1.8').should_not == ver('ruby')
  end
  it "should compare to versioned VersionOfs" do
    ver('ruby'       ).should_not == ver('ruby', '1.8')
    ver('ruby', '1.8').should     == ver('ruby', '1.8')
    ver('ruby', '1.8').should_not == ver('ruby', '1.9')
  end
end

describe "matching" do
  it "should match all versions when unversioned" do
    ver('ruby').matches?(VersionStr.new('1.8')).should be_true
    ver('ruby').matches?(VersionStr.new('1.9')).should be_true
  end
  it "should only match the correct version" do
    ver('ruby', '1.8').matches?(VersionStr.new('1.8')).should be_true
    ver('ruby', '1.8').matches?(VersionStr.new('1.9')).should be_false
    ver('ruby', '1.8').matches?(VersionStr.new('>= 1.7')).should be_true
    ver('ruby', '1.9').matches?(VersionStr.new('~> 1.8')).should be_true
    ver('ruby', '2.0').matches?(VersionStr.new('~> 1.8')).should be_false
  end
end