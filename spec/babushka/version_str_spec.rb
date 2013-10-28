require 'spec_helper'
require 'version_str_support'

describe "parsing" do
  it "should parse the version number" do
    VersionStr.new('0.2').pieces.should == [0, 2]
    VersionStr.new('0.3.10.2').pieces.should == [0, 3, 10, 2]
    VersionStr.new('1.9.1-p243').pieces.should == [1, 9, 1, 'p', 243]
    VersionStr.new('3.0.0.beta').pieces.should == [3, 0, 0, 'beta']
    VersionStr.new('3.0.0.beta3').pieces.should == [3, 0, 0, 'beta', 3]
    VersionStr.new('R13B04').pieces.should == ['R', 13, 'B', 4]
    VersionStr.new('HEAD').pieces.should == ['HEAD']
  end
  it "should parse the operator if supplied" do
    v = VersionStr.new('>0.2')
    v.pieces.should == [0, 2]
    v.operator.should == '>'

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
  it "should ignore a leading 'v' for 'version'" do
    v = VersionStr.new('V0.5.0')
    v.pieces.should == [0, 5, 0]
    v.operator.should == '=='

    v = VersionStr.new('>= v1.9.2p180')
    v.pieces.should == [1, 9, 2, 'p', 180]
    v.operator.should == '>='
  end
  describe "invalid operators" do
    it "should reject them" do
      L{
        VersionStr.new('~ 0.2')
      }.should raise_error(InvalidVersionOperator, "VersionStr.new('~ 0.2'): invalid operator '~'.")
      L{
        VersionStr.new('>> 0.2')
      }.should raise_error(InvalidVersionOperator, "VersionStr.new('>> 0.2'): invalid operator '>>'.")
    end
  end
  describe "invalid version numbers" do
    it "should reject version numbers that don't contain any digits" do
      L{
        VersionStr.new('nginx')
      }.should raise_error(InvalidVersionStr, "VersionStr.new('nginx'): couldn't parse a version number.")
    end
    it "should reject numbers containing spaces" do
      L{
        VersionStr.new('0. 2')
      }.should raise_error(InvalidVersionStr, "VersionStr.new('0. 2'): couldn't parse a version number.")
    end
    it "should reject numbers containing unexpected chars" do
      L{
        VersionStr.new('0.2!')
      }.should raise_error(InvalidVersionStr, "VersionStr.new('0.2!'): couldn't parse a version number.")
    end
  end
end

describe '#parseable_version?' do
  it 'should not report emptyness as parseable' do
    VersionStr.parseable_version?(nil).should be_false
    VersionStr.parseable_version?('').should be_false
    VersionStr.parseable_version?('  ').should be_false
  end
  it "should not report digitless input as parseable" do
    VersionStr.parseable_version?('nginx').should be_false
  end
  it "should not report input with digits as parseable" do
    VersionStr.parseable_version?('3').should be_true
    VersionStr.parseable_version?('R13B04').should be_true
    VersionStr.parseable_version?('1.9.3-p0').should be_true
  end
end

describe 'rendering' do
  it "should render just the version number with no operator" do
    VersionStr.new('0.3.1').to_s.should == '0.3.1'
  end
  it "should render the full string with an operator" do
    VersionStr.new('= 0.3.1').to_s.should == '0.3.1'
    VersionStr.new('== 0.3.1').to_s.should == '0.3.1'
    VersionStr.new('~> 0.3.1').to_s.should == '~> 0.3.1'
  end
  it "should keep string pieces" do
    VersionStr.new('3.0.0.beta').to_s.should == '3.0.0.beta'
  end
  it "should preserve the original formatting" do
    VersionStr.new('1.8.7-p174-src').to_s.should == '1.8.7-p174-src'
    VersionStr.new('3.0.0-beta').to_s.should == '3.0.0-beta'
  end
end

def compare_with operator
  pairs.zip(results[operator]).each {|pair,expected|
    result = Babushka::VersionStr.new(pair.first).send operator, Babushka::VersionStr.new(pair.last)
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

  it "should treat word pieces as less than no piece" do
    (VersionStr.new('3.0.0') > VersionStr.new('3.0.0.beta')).should be_true
    (VersionStr.new('3.0.0') > VersionStr.new('3.0.0.beta1')).should be_true
    (VersionStr.new('1.0.0') > VersionStr.new('1.0.0.rc.5')).should be_true
  end

  it "should compare word pieces alphabetically" do
    (VersionStr.new('3.0.0.beta') < VersionStr.new('3.0.0.pre')).should be_true
    (VersionStr.new('3.0.0.pre') < VersionStr.new('3.0.0.rc')).should be_true
  end

  it "should treat word pieces with a number as more than without one" do
    (VersionStr.new('3.0.0.beta1') > VersionStr.new('3.0.0.beta')).should be_true
  end

  it "should compare number parts of word pieces numerically" do
    (VersionStr.new('3.0.0.beta2') > VersionStr.new('3.0.0.beta1')).should be_true
    (VersionStr.new('3.0.0.beta10') > VersionStr.new('3.0.0.beta1')).should be_true
  end

  it "should allow for integers in strings and sort correctly" do
    (VersionStr.new('3.0.0.beta12') > VersionStr.new('3.0.0.beta2')).should be_true
    (VersionStr.new('R13B04') > VersionStr.new('R2B9')).should be_true
  end
end
