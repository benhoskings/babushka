require 'spec_helper'

describe "creation" do
  it "should store name" do
    Babushka.VersionOf('ruby').name.should == 'ruby'
  end
  it "should accept versions, optionally" do
    Babushka.VersionOf('ruby').version.should == nil
    Babushka.VersionOf('ruby', '1.8').version.to_s.should == '1.8'
    Babushka.VersionOf('ruby', '1.8'.to_version).version.to_s.should == '1.8'
  end
  it "should accept name & version in one string" do
    Babushka.VersionOf('ruby 1.8').version.to_s.should == '1.8'
    Babushka.VersionOf('ruby >= 1.9').version.to_s.should == '>= 1.9'
  end
  it "should handle array args" do
    Babushka.VersionOf(['ruby', '1.8']).version.to_s.should == '1.8'
  end
  it "should accept existing VersionOf instances" do
    Babushka.VersionOf(Babushka.VersionOf('ruby')).should == Babushka.VersionOf('ruby')
    Babushka.VersionOf(Babushka.VersionOf('ruby', '1.8')).should == Babushka.VersionOf('ruby', '1.8')
    Babushka.VersionOf(Babushka.VersionOf('ruby', '1.8'), '1.9').should == Babushka.VersionOf('ruby', '1.9')
  end
end

describe "to_s" do
  describe "versionless" do
    it "should be just the name" do
      Babushka.VersionOf('ruby').to_s.should == 'ruby'
    end
  end
  describe "nameless" do
    it "should be just the version" do
      Babushka.VersionOf(nil, '1.8').to_s.should == '1.8'
    end
  end
  describe "versioned" do
    it "should be separated with -" do
      Babushka.VersionOf('ruby', '1.8').to_s.should == 'ruby-1.8'
    end
  end
end

describe "equality" do
  it "should compare to versionless strings" do
    Babushka.VersionOf('ruby'       ).should     == Babushka.VersionOf('ruby')
    Babushka.VersionOf('ruby', '1.8').should_not == Babushka.VersionOf('ruby')
  end
  it "should compare to versioned strings" do
    Babushka.VersionOf('ruby'       ).should_not == Babushka.VersionOf('ruby', '1.8')
    Babushka.VersionOf('ruby', '1.8').should     == Babushka.VersionOf('ruby', '1.8')
    Babushka.VersionOf('ruby', '1.8').should_not == Babushka.VersionOf('ruby', '1.9')
  end
  it "should compare to versionless VersionOfs" do
    Babushka.VersionOf('ruby'       ).should     == Babushka.VersionOf('ruby')
    Babushka.VersionOf('ruby', '1.8').should_not == Babushka.VersionOf('ruby')
  end
  it "should compare to versioned VersionOfs" do
    Babushka.VersionOf('ruby'       ).should_not == Babushka.VersionOf('ruby', '1.8')
    Babushka.VersionOf('ruby', '1.8').should     == Babushka.VersionOf('ruby', '1.8')
    Babushka.VersionOf('ruby', '1.8').should_not == Babushka.VersionOf('ruby', '1.9')
  end
end

describe "comparisons" do
  it "should fail when the names don't match" do
    L{
      Babushka.VersionOf('ruby', '1.8') <=> Babushka.VersionOf('mongo', '1.4.2')
    }.should raise_error(ArgumentError, "You can't compare the versions of two different things (ruby, mongo).")
  end
  it "should defer to VersionStr#<=>" do
    (Babushka.VersionOf('ruby', '1.8') <=> Babushka.VersionOf('ruby', '1.9')).should == -1
    (Babushka.VersionOf('ruby', '1.8') <=> Babushka.VersionOf('ruby', '1.8')).should == 0
    (Babushka.VersionOf('ruby', '1.8.7') <=> Babushka.VersionOf('ruby', '1.8')).should == 1
    (Babushka.VersionOf('ruby', '1.8.7') <=> Babushka.VersionOf('ruby', '1.9.1')).should == -1
  end
end

describe "matching" do
  describe "against strings" do
    it "should match all versions when unversioned" do
      Babushka.VersionOf('ruby').matches?('1.8').should be_true
      Babushka.VersionOf('ruby').matches?('1.9').should be_true
    end
    it "should only match the correct version" do
      Babushka.VersionOf('ruby', '1.8').matches?('1.8').should be_true
      Babushka.VersionOf('ruby', '1.9').matches?('1.8').should be_false
      Babushka.VersionOf('ruby', '>= 1.7').matches?('1.8').should be_true
      Babushka.VersionOf('ruby', '~> 1.8').matches?('1.9').should be_true
      Babushka.VersionOf('ruby', '~> 1.8').matches?('2.0').should be_false
    end
  end
  describe "against VersionStrs" do
    it "should match all versions when unversioned" do
      Babushka.VersionOf('ruby').matches?('1.8'.to_version).should be_true
      Babushka.VersionOf('ruby').matches?('1.9'.to_version).should be_true
    end
    it "should only match the correct version" do
      Babushka.VersionOf('ruby', '1.8').matches?('1.8'.to_version).should be_true
      Babushka.VersionOf('ruby', '1.9').matches?('1.8'.to_version).should be_false
      Babushka.VersionOf('ruby', '>= 1.7').matches?('1.8'.to_version).should be_true
      Babushka.VersionOf('ruby', '~> 1.8').matches?('1.9'.to_version).should be_true
      Babushka.VersionOf('ruby', '~> 1.8').matches?('2.0'.to_version).should be_false
    end
  end
end
