require 'spec/spec_support'

describe "creation" do
  it "should store name" do
    VersionOf.new('ruby').name.should == 'ruby'
  end
  it "should accept versions, optionally" do
    VersionOf.new('ruby').version.should == nil
    VersionOf.new('ruby', '1.8').version.to_s.should == '1.8'
    VersionOf.new('ruby', '1.8'.to_version).version.to_s.should == '1.8'
  end
end

describe "version strings" do
  it "should return just the name when no version is given" do
    VersionOf.new('ruby').to_s.should == 'ruby'
  end
  it "should return a versioned name when a version is given" do
    VersionOf.new('ruby', '1.8').to_s.should == 'ruby-1.8'
    VersionOf.new('ruby', '1.8'.to_version).to_s.should == 'ruby-1.8'
  end
end
