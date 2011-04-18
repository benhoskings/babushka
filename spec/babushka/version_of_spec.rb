require 'spec_helper'

describe "creation" do
  it "should store name" do
    VersionOf('ruby').name.should == 'ruby'
  end
  it "should accept versions, optionally" do
    VersionOf('ruby').version.should == nil
    VersionOf('ruby', '1.8').version.to_s.should == '1.8'
    VersionOf('ruby', '1.8'.to_version).version.to_s.should == '1.8'
  end
  it "should accept name & version in one string" do
    VersionOf('ruby 1.8').version.to_s.should == '1.8'
    VersionOf('ruby >= 1.9').version.to_s.should == '>= 1.9'
  end
  it "should handle array args" do
    VersionOf(['ruby', '1.8']).version.to_s.should == '1.8'
  end
  it "should accept existing VersionOf instances" do
    VersionOf(VersionOf('ruby')).should == VersionOf('ruby')
    VersionOf(VersionOf('ruby', '1.8')).should == VersionOf('ruby', '1.8')
    VersionOf(VersionOf('ruby', '1.8'), '1.9').should == VersionOf('ruby', '1.9')
  end
end

describe "to_s" do
  describe "versionless" do
    it "should be just the name" do
      VersionOf('ruby').to_s.should == 'ruby'
    end
  end
  describe "nameless" do
    it "should be just the version" do
      VersionOf(nil, '1.8').to_s.should == '1.8'
    end
  end
  describe "versioned" do
    it "should be separated with -" do
      VersionOf('ruby', '1.8').to_s.should == 'ruby-1.8'
    end
  end
end

describe "equality" do
  it "should compare to versionless strings" do
    VersionOf('ruby'       ).should     == VersionOf('ruby')
    VersionOf('ruby', '1.8').should_not == VersionOf('ruby')
  end
  it "should compare to versioned strings" do
    VersionOf('ruby'       ).should_not == VersionOf('ruby', '1.8')
    VersionOf('ruby', '1.8').should     == VersionOf('ruby', '1.8')
    VersionOf('ruby', '1.8').should_not == VersionOf('ruby', '1.9')
  end
  it "should compare to versionless VersionOfs" do
    VersionOf('ruby'       ).should     == VersionOf('ruby')
    VersionOf('ruby', '1.8').should_not == VersionOf('ruby')
  end
  it "should compare to versioned VersionOfs" do
    VersionOf('ruby'       ).should_not == VersionOf('ruby', '1.8')
    VersionOf('ruby', '1.8').should     == VersionOf('ruby', '1.8')
    VersionOf('ruby', '1.8').should_not == VersionOf('ruby', '1.9')
  end
end

describe "comparisons" do
  it "should fail when the names don't match" do
    L{
      VersionOf('ruby', '1.8') <=> VersionOf('mongo', '1.4.2')
    }.should raise_error(ArgumentError, "You can't compare the versions of two different things (ruby, mongo).")
  end
  it "should defer to VersionStr#<=>" do
    (VersionOf('ruby', '1.8') <=> VersionOf('ruby', '1.9')).should == -1
    (VersionOf('ruby', '1.8') <=> VersionOf('ruby', '1.8')).should == 0
    (VersionOf('ruby', '1.8.7') <=> VersionOf('ruby', '1.8')).should == 1
    (VersionOf('ruby', '1.8.7') <=> VersionOf('ruby', '1.9.1')).should == -1
  end
end

describe "matching" do
  describe "against strings" do
    it "should match all versions when unversioned" do
      VersionOf('ruby').matches?('1.8').should be_true
      VersionOf('ruby').matches?('1.9').should be_true
    end
    it "should only match the correct version" do
      VersionOf('ruby', '1.8').matches?('1.8').should be_true
      VersionOf('ruby', '1.9').matches?('1.8').should be_false
      VersionOf('ruby', '>= 1.7').matches?('1.8').should be_true
      VersionOf('ruby', '~> 1.8').matches?('1.9').should be_true
      VersionOf('ruby', '~> 1.8').matches?('2.0').should be_false
    end
  end
  describe "against VersionStrs" do
    it "should match all versions when unversioned" do
      VersionOf('ruby').matches?('1.8'.to_version).should be_true
      VersionOf('ruby').matches?('1.9'.to_version).should be_true
    end
    it "should only match the correct version" do
      VersionOf('ruby', '1.8').matches?('1.8'.to_version).should be_true
      VersionOf('ruby', '1.9').matches?('1.8'.to_version).should be_false
      VersionOf('ruby', '>= 1.7').matches?('1.8'.to_version).should be_true
      VersionOf('ruby', '~> 1.8').matches?('1.9'.to_version).should be_true
      VersionOf('ruby', '~> 1.8').matches?('2.0'.to_version).should be_false
    end
  end
end
