require 'spec_support'
require 'version_str_support'

def compare_with operator
  pairs.zip(results[operator]).each {|pair,expected|
    result = VersionStr.new(pair.first).send operator, VersionStr.new(pair.last)
    it "#{pair.first} #{operator} #{pair.last}: #{result}" do
      result.should == expected
    end
  }
end

%w[== != > < >= <= ~>].each do |operator|
  describe operator do
    compare_with operator
  end
end

describe "comparing" do
  it "should work with other VersionStrs" do
    (VersionStr.new('0.3.1') > VersionStr.new('0.2.9')).should be_true
  end
  it "should work with strings" do
    (VersionStr.new('0.3.1') > '0.2.9').should be_true
  end
end

describe "parsing" do
  it "should parse the version number" do
    VersionStr.new('0.2').pieces.should == [0, 2]
    VersionStr.new('0.3.10.2').pieces.should == [0, 3, 10, 2]
  end
  it "should parse the operator if supplied" do
    v = VersionStr.new('>= 0.2')
    v.pieces.should == [0, 2]
    v.operator.should == '>='

    v = VersionStr.new(' ~>  0.3.10.2')
    v.pieces.should == [0, 3, 10, 2]
    v.operator.should == '~>'
  end
  it "should convert = to ==" do
    v = VersionStr.new('= 0.2')
    v.pieces.should == [0, 2]
    v.operator.should == '=='

    v = VersionStr.new('== 0.2')
    v.pieces.should == [0, 2]
    v.operator.should == '=='
  end
  it "should ignore patchlevel suffixes" do
    VersionStr.new('1.9.1-p243').pieces.should == [1, 9, 1]
  end
  it "should reject invalid operators" do
    L{
      VersionStr.new('~ 0.2')
    }.should raise_error "Bad input: '~ 0.2'"

    L{
      VersionStr.new('>> 0.2')
    }.should raise_error "Bad input: '>> 0.2'"
  end
end

describe 'rendering' do
  it "should render just the version number with no operator" do
    VersionStr.new('0.3.1').to_s.should == '0.3.1'
  end
  it "should render the full string with an operator" do
    VersionStr.new('= 0.3.1').to_s.should == '= 0.3.1'
    VersionStr.new('== 0.3.1').to_s.should == '= 0.3.1'
    VersionStr.new('~> 0.3.1').to_s.should == '~> 0.3.1'
  end
end
