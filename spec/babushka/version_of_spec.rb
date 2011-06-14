require 'spec_helper'

def version_of *args
  Babushka::VersionOf::Helpers.VersionOf *args
end

describe "creation" do
  it "should store name" do
    version_of('ruby').name.should == 'ruby'
  end
  it "should accept versions, optionally" do
    version_of('ruby').version.should == nil
    version_of('ruby', '1.8').version.to_s.should == '1.8'
    version_of('ruby', '1.8'.to_version).version.to_s.should == '1.8'
  end
  it "should accept name & version in one string" do
    version_of('ruby 1.8').version.to_s.should == '1.8'
    version_of('ruby >= 1.9').version.to_s.should == '>= 1.9'
  end
  it "should handle array args" do
    version_of(['ruby', '1.8']).version.to_s.should == '1.8'
  end
  it "should accept existing VersionOf instances" do
    version_of(version_of('ruby')).should == version_of('ruby')
    version_of(version_of('ruby', '1.8')).should == version_of('ruby', '1.8')
    version_of(version_of('ruby', '1.8'), '1.9').should == version_of('ruby', '1.9')
  end
end

describe "to_s" do
  describe "versionless" do
    it "should be just the name" do
      version_of('ruby').to_s.should == 'ruby'
    end
  end
  describe "nameless" do
    it "should be just the version" do
      version_of(nil, '1.8').to_s.should == '1.8'
    end
  end
  describe "versioned" do
    it "should be separated with -" do
      version_of('ruby', '1.8').to_s.should == 'ruby-1.8'
    end
  end
end

describe "equality" do
  it "should compare to versionless strings" do
    version_of('ruby'       ).should     == version_of('ruby')
    version_of('ruby', '1.8').should_not == version_of('ruby')
  end
  it "should compare to versioned strings" do
    version_of('ruby'       ).should_not == version_of('ruby', '1.8')
    version_of('ruby', '1.8').should     == version_of('ruby', '1.8')
    version_of('ruby', '1.8').should_not == version_of('ruby', '1.9')
  end
  it "should compare to versionless VersionOfs" do
    version_of('ruby'       ).should     == version_of('ruby')
    version_of('ruby', '1.8').should_not == version_of('ruby')
  end
  it "should compare to versioned VersionOfs" do
    version_of('ruby'       ).should_not == version_of('ruby', '1.8')
    version_of('ruby', '1.8').should     == version_of('ruby', '1.8')
    version_of('ruby', '1.8').should_not == version_of('ruby', '1.9')
  end
end

describe "comparisons" do
  it "should fail when the names don't match" do
    L{
      version_of('ruby', '1.8') <=> version_of('mongo', '1.4.2')
    }.should raise_error(ArgumentError, "You can't compare the versions of two different things (ruby, mongo).")
  end
  it "should defer to VersionStr#<=>" do
    (version_of('ruby', '1.8') <=> version_of('ruby', '1.9')).should == -1
    (version_of('ruby', '1.8') <=> version_of('ruby', '1.8')).should == 0
    (version_of('ruby', '1.8.7') <=> version_of('ruby', '1.8')).should == 1
    (version_of('ruby', '1.8.7') <=> version_of('ruby', '1.9.1')).should == -1
  end
end

describe "matching" do
  describe "against strings" do
    it "should match all versions when unversioned" do
      version_of('ruby').matches?('1.8').should be_true
      version_of('ruby').matches?('1.9').should be_true
    end
    it "should only match the correct version" do
      version_of('ruby', '1.8').matches?('1.8').should be_true
      version_of('ruby', '1.9').matches?('1.8').should be_false
      version_of('ruby', '>= 1.7').matches?('1.8').should be_true
      version_of('ruby', '~> 1.8').matches?('1.9').should be_true
      version_of('ruby', '~> 1.8').matches?('2.0').should be_false
    end
  end
  describe "against VersionStrs" do
    it "should match all versions when unversioned" do
      version_of('ruby').matches?('1.8'.to_version).should be_true
      version_of('ruby').matches?('1.9'.to_version).should be_true
    end
    it "should only match the correct version" do
      version_of('ruby', '1.8').matches?('1.8'.to_version).should be_true
      version_of('ruby', '1.9').matches?('1.8'.to_version).should be_false
      version_of('ruby', '>= 1.7').matches?('1.8'.to_version).should be_true
      version_of('ruby', '~> 1.8').matches?('1.9'.to_version).should be_true
      version_of('ruby', '~> 1.8').matches?('2.0'.to_version).should be_false
    end
  end
end
