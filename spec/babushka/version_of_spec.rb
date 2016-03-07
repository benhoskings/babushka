require 'spec_helper'

def version_of *args
  Babushka.VersionOf(*args)
end

RSpec.describe "creation" do
  it "should store name" do
    expect(version_of('ruby').name).to eq('ruby')
  end
  it "should accept versions, optionally" do
    expect(version_of('ruby').version).to eq(nil)
    expect(version_of('ruby', '1.8').version.to_s).to eq('1.8')
    expect(version_of('ruby', '1.8'.to_version).version.to_s).to eq('1.8')
  end
  it "should accept name & version in one string" do
    expect(version_of('ruby 1.8').version.to_s).to eq('1.8')
    expect(version_of('ruby >= 1.9').version.to_s).to eq('>= 1.9')
  end
  it "should handle array args" do
    expect(version_of(['ruby', '1.8']).version.to_s).to eq('1.8')
  end
  it "should accept existing VersionOf instances" do
    expect(version_of(version_of('ruby'))).to eq(version_of('ruby'))
    expect(version_of(version_of('ruby', '1.8'))).to eq(version_of('ruby', '1.8'))
    expect(version_of(version_of('ruby', '1.8'), '1.9')).to eq(version_of('ruby', '1.9'))
  end
  it "should accept name with space" do
    expect(version_of('Google Chrome.app').name).to eq('Google Chrome.app')
    expect(version_of('Google Chrome.app').version).to eq(nil)
  end
  # TODO: This is tricky, e.g. splitting "Sublime Text 2 >= 2.0.1".
  # it "should accept name with space and version"
end

RSpec.describe "to_s" do
  describe "versionless" do
    it "should be just the name" do
      expect(version_of('ruby').to_s).to eq('ruby')
    end
  end
  describe "nameless" do
    it "should be just the version" do
      expect(version_of(nil, '1.8').to_s).to eq('1.8')
    end
  end
  describe "versioned" do
    it "should be separated with - when no operator is specified" do
      expect(version_of('ruby', '1.8').to_s).to eq('ruby-1.8')
    end
    it "should be separated with - when the operator is ==" do
      expect(version_of('ruby', '== 1.8').to_s).to eq('ruby-1.8')
    end
    it "should be separated with - when no version is specified" do
      expect(version_of('ruby', '>= 1.8').to_s).to eq('ruby >= 1.8')
    end
  end
end

RSpec.describe '#exact?' do
  it "should be false when there is no version" do
    expect(version_of('ruby')).not_to be_exact
  end
  it "should be true when there is a just version number" do
    expect(version_of('ruby', '1.8')).to be_exact
  end
  it "should be true when the operator is ==" do
    expect(version_of('ruby', '== 1.8')).to be_exact
  end
  it "should be false when the operator is not ==" do
    expect(version_of('ruby', '>= 1.8')).not_to be_exact
  end
end

RSpec.describe "equality" do
  it "should compare to versionless strings" do
    expect(version_of('ruby'       )).to     eq(version_of('ruby'))
    expect(version_of('ruby', '1.8')).not_to eq(version_of('ruby'))
  end
  it "should compare to versioned strings" do
    expect(version_of('ruby'       )).not_to eq(version_of('ruby', '1.8'))
    expect(version_of('ruby', '1.8')).to     eq(version_of('ruby', '1.8'))
    expect(version_of('ruby', '1.8')).not_to eq(version_of('ruby', '1.9'))
  end
  it "should compare to versionless VersionOfs" do
    expect(version_of('ruby'       )).to     eq(version_of('ruby'))
    expect(version_of('ruby', '1.8')).not_to eq(version_of('ruby'))
  end
  it "should compare to versioned VersionOfs" do
    expect(version_of('ruby'       )).not_to eq(version_of('ruby', '1.8'))
    expect(version_of('ruby', '1.8')).to     eq(version_of('ruby', '1.8'))
    expect(version_of('ruby', '1.8')).not_to eq(version_of('ruby', '1.9'))
  end
end

RSpec.describe "comparator" do
  it "should return nil on nil input" do
    expect(version_of('ruby', '1.8') <=> nil).to be_nil
  end
  it "should return nil when the names don't match" do
    expect(version_of('ruby', '1.8') <=> version_of('mongo', '1.4.2')).to be_nil
  end
  it "should defer to VersionStr#<=>" do
    expect(version_of('ruby', '1.8') <=> version_of('ruby', '1.9')).to eq(-1)
    expect(version_of('ruby', '1.8') <=> version_of('ruby', '1.8')).to eq(0)
    expect(version_of('ruby', '1.8.7') <=> version_of('ruby', '1.8')).to eq(1)
    expect(version_of('ruby', '1.8.7') <=> version_of('ruby', '1.9.1')).to eq(-1)
  end
end

RSpec.describe "matching" do
  describe "against strings" do
    it "should match all versions when unversioned" do
      expect(version_of('ruby').matches?('1.8')).to be_truthy
      expect(version_of('ruby').matches?('1.9')).to be_truthy
    end
    it "should only match the correct version" do
      expect(version_of('ruby', '1.8').matches?('1.8')).to be_truthy
      expect(version_of('ruby', '1.9').matches?('1.8')).to be_falsey
      expect(version_of('ruby', '>= 1.7').matches?('1.8')).to be_truthy
      expect(version_of('ruby', '~> 1.8').matches?('1.9')).to be_truthy
      expect(version_of('ruby', '~> 1.8').matches?('2.0')).to be_falsey
    end
  end
  describe "against VersionStrs" do
    it "should match all versions when unversioned" do
      expect(version_of('ruby').matches?('1.8'.to_version)).to be_truthy
      expect(version_of('ruby').matches?('1.9'.to_version)).to be_truthy
    end
    it "should only match the correct version" do
      expect(version_of('ruby', '1.8').matches?('1.8'.to_version)).to be_truthy
      expect(version_of('ruby', '1.9').matches?('1.8'.to_version)).to be_falsey
      expect(version_of('ruby', '>= 1.7').matches?('1.8'.to_version)).to be_truthy
      expect(version_of('ruby', '~> 1.8').matches?('1.9'.to_version)).to be_truthy
      expect(version_of('ruby', '~> 1.8').matches?('2.0'.to_version)).to be_falsey
    end
  end
end
