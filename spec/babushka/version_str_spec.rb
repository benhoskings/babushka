require 'spec_helper'
require 'version_str_support'

describe "parsing" do
  it "should parse the version number" do
    Babushka::VersionStr.new('0.2').pieces.should == [0, 2]
    Babushka::VersionStr.new('0.3.10.2').pieces.should == [0, 3, 10, 2]
    Babushka::VersionStr.new('1.9.1-p243').pieces.should == [1, 9, 1, 'p', 243]
    Babushka::VersionStr.new('3.0.0.beta').pieces.should == [3, 0, 0, 'beta']
    Babushka::VersionStr.new('3.0.0.beta3').pieces.should == [3, 0, 0, 'beta', 3]
    Babushka::VersionStr.new('R13B04').pieces.should == ['R', 13, 'B', 4]
    Babushka::VersionStr.new('HEAD').pieces.should == ['HEAD']
  end
  it "should parse the operator if supplied" do
    v = Babushka::VersionStr.new('>0.2')
    v.pieces.should == [0, 2]
    v.operator.should == '>'

    v = Babushka::VersionStr.new('>= 0.2')
    v.pieces.should == [0, 2]
    v.operator.should == '>='

    v = Babushka::VersionStr.new(' ~>  0.3.10.2')
    v.pieces.should == [0, 3, 10, 2]
    v.operator.should == '~>'
  end
  it "should convert = to ==" do
    v = Babushka::VersionStr.new('= 0.2')
    v.pieces.should == [0, 2]
    v.operator.should == '=='

    v = Babushka::VersionStr.new('== 0.2')
    v.pieces.should == [0, 2]
    v.operator.should == '=='
  end
  it "should ignore a leading 'v' for 'version'" do
    v = Babushka::VersionStr.new('V0.5.0')
    v.pieces.should == [0, 5, 0]
    v.operator.should == '=='

    v = Babushka::VersionStr.new('>= v1.9.2p180')
    v.pieces.should == [1, 9, 2, 'p', 180]
    v.operator.should == '>='
  end
  describe "invalid operators" do
    it "should reject them" do
      L{
        Babushka::VersionStr.new('~ 0.2')
      }.should raise_error(Babushka::InvalidVersionOperator, "Babushka::VersionStr.new('~ 0.2'): invalid operator '~'.")
      L{
        Babushka::VersionStr.new('>> 0.2')
      }.should raise_error(Babushka::InvalidVersionOperator, "Babushka::VersionStr.new('>> 0.2'): invalid operator '>>'.")
    end
  end
  describe "invalid version numbers" do
    it "should reject version numbers that don't contain any digits" do
      L{
        Babushka::VersionStr.new('nginx')
      }.should raise_error(Babushka::InvalidVersionStr, "Babushka::VersionStr.new('nginx'): couldn't parse a version number.")
    end
    it "should reject numbers containing spaces" do
      L{
        Babushka::VersionStr.new('0. 2')
      }.should raise_error(Babushka::InvalidVersionStr, "Babushka::VersionStr.new('0. 2'): couldn't parse a version number.")
    end
    it "should reject numbers containing unexpected chars" do
      L{
        Babushka::VersionStr.new('0.2!')
      }.should raise_error(Babushka::InvalidVersionStr, "Babushka::VersionStr.new('0.2!'): couldn't parse a version number.")
    end
  end
end

describe '#parseable_version?' do
  it 'should not report emptyness as parseable' do
    Babushka::VersionStr.parseable_version?(nil).should be_falsey
    Babushka::VersionStr.parseable_version?('').should be_falsey
    Babushka::VersionStr.parseable_version?('  ').should be_falsey
  end
  it "should not report digitless input as parseable" do
    Babushka::VersionStr.parseable_version?('nginx').should be_falsey
  end
  it "should not report input with digits as parseable" do
    Babushka::VersionStr.parseable_version?('3').should be_truthy
    Babushka::VersionStr.parseable_version?('R13B04').should be_truthy
    Babushka::VersionStr.parseable_version?('1.9.3-p0').should be_truthy
  end
end

describe 'rendering' do
  it "should render just the version number with no operator" do
    Babushka::VersionStr.new('0.3.1').to_s.should == '0.3.1'
  end
  it "should render the full string with an operator" do
    Babushka::VersionStr.new('= 0.3.1').to_s.should == '0.3.1'
    Babushka::VersionStr.new('== 0.3.1').to_s.should == '0.3.1'
    Babushka::VersionStr.new('~> 0.3.1').to_s.should == '~> 0.3.1'
  end
  it "should keep string pieces" do
    Babushka::VersionStr.new('3.0.0.beta').to_s.should == '3.0.0.beta'
  end
  it "should preserve the original formatting" do
    Babushka::VersionStr.new('1.8.7-p174-src').to_s.should == '1.8.7-p174-src'
    Babushka::VersionStr.new('3.0.0-beta').to_s.should == '3.0.0-beta'
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

describe "comparator" do
  it "should return nil on nil input" do
    (Babushka::VersionStr.new('0.3.1') <=> nil).should be_nil
  end
end

describe "comparing" do
  it "should work with other VersionStrs" do
    (Babushka::VersionStr.new('0.3.1') > Babushka::VersionStr.new('0.2.9')).should be_truthy
  end

  it "should work with strings" do
    (Babushka::VersionStr.new('0.3.1') > '0.2.9').should be_truthy
  end

  it "should treat word pieces as less than no piece" do
    (Babushka::VersionStr.new('3.0.0') > Babushka::VersionStr.new('3.0.0.beta')).should be_truthy
    (Babushka::VersionStr.new('3.0.0') > Babushka::VersionStr.new('3.0.0.beta1')).should be_truthy
    (Babushka::VersionStr.new('1.0.0') > Babushka::VersionStr.new('1.0.0.rc.5')).should be_truthy
  end

  it "should compare word pieces alphabetically" do
    (Babushka::VersionStr.new('3.0.0.beta') < Babushka::VersionStr.new('3.0.0.pre')).should be_truthy
    (Babushka::VersionStr.new('3.0.0.pre') < Babushka::VersionStr.new('3.0.0.rc')).should be_truthy
  end

  it "should treat word pieces with a number as more than without one" do
    (Babushka::VersionStr.new('3.0.0.beta1') > Babushka::VersionStr.new('3.0.0.beta')).should be_truthy
  end

  it "should compare number parts of word pieces numerically" do
    (Babushka::VersionStr.new('3.0.0.beta2') > Babushka::VersionStr.new('3.0.0.beta1')).should be_truthy
    (Babushka::VersionStr.new('3.0.0.beta10') > Babushka::VersionStr.new('3.0.0.beta1')).should be_truthy
  end

  it "should allow for integers in strings and sort correctly" do
    (Babushka::VersionStr.new('3.0.0.beta12') > Babushka::VersionStr.new('3.0.0.beta2')).should be_truthy
    (Babushka::VersionStr.new('R13B04') > Babushka::VersionStr.new('R2B9')).should be_truthy
  end
end
