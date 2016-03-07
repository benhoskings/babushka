require 'spec_helper'
require 'version_str_support'

describe "parsing" do
  it "should parse the version number" do
    expect(Babushka::VersionStr.new('0.2').pieces).to eq([0, 2])
    expect(Babushka::VersionStr.new('0.3.10.2').pieces).to eq([0, 3, 10, 2])
    expect(Babushka::VersionStr.new('1.9.1-p243').pieces).to eq([1, 9, 1, 'p', 243])
    expect(Babushka::VersionStr.new('3.0.0.beta').pieces).to eq([3, 0, 0, 'beta'])
    expect(Babushka::VersionStr.new('3.0.0.beta3').pieces).to eq([3, 0, 0, 'beta', 3])
    expect(Babushka::VersionStr.new('R13B04').pieces).to eq(['R', 13, 'B', 4])
    expect(Babushka::VersionStr.new('HEAD').pieces).to eq(['HEAD'])
  end
  it "should parse the operator if supplied" do
    v = Babushka::VersionStr.new('>0.2')
    expect(v.pieces).to eq([0, 2])
    expect(v.operator).to eq('>')

    v = Babushka::VersionStr.new('>= 0.2')
    expect(v.pieces).to eq([0, 2])
    expect(v.operator).to eq('>=')

    v = Babushka::VersionStr.new(' ~>  0.3.10.2')
    expect(v.pieces).to eq([0, 3, 10, 2])
    expect(v.operator).to eq('~>')
  end
  it "should convert = to ==" do
    v = Babushka::VersionStr.new('= 0.2')
    expect(v.pieces).to eq([0, 2])
    expect(v.operator).to eq('==')

    v = Babushka::VersionStr.new('== 0.2')
    expect(v.pieces).to eq([0, 2])
    expect(v.operator).to eq('==')
  end
  it "should ignore a leading 'v' for 'version'" do
    v = Babushka::VersionStr.new('V0.5.0')
    expect(v.pieces).to eq([0, 5, 0])
    expect(v.operator).to eq('==')

    v = Babushka::VersionStr.new('>= v1.9.2p180')
    expect(v.pieces).to eq([1, 9, 2, 'p', 180])
    expect(v.operator).to eq('>=')
  end
  describe "invalid operators" do
    it "should reject them" do
      expect(L{
        Babushka::VersionStr.new('~ 0.2')
      }).to raise_error(Babushka::InvalidVersionOperator, "Babushka::VersionStr.new('~ 0.2'): invalid operator '~'.")
      expect(L{
        Babushka::VersionStr.new('>> 0.2')
      }).to raise_error(Babushka::InvalidVersionOperator, "Babushka::VersionStr.new('>> 0.2'): invalid operator '>>'.")
    end
  end
  describe "invalid version numbers" do
    it "should reject version numbers that don't contain any digits" do
      expect(L{
        Babushka::VersionStr.new('nginx')
      }).to raise_error(Babushka::InvalidVersionStr, "Babushka::VersionStr.new('nginx'): couldn't parse a version number.")
    end
    it "should reject numbers containing spaces" do
      expect(L{
        Babushka::VersionStr.new('0. 2')
      }).to raise_error(Babushka::InvalidVersionStr, "Babushka::VersionStr.new('0. 2'): couldn't parse a version number.")
    end
    it "should reject numbers containing unexpected chars" do
      expect(L{
        Babushka::VersionStr.new('0.2!')
      }).to raise_error(Babushka::InvalidVersionStr, "Babushka::VersionStr.new('0.2!'): couldn't parse a version number.")
    end
  end
end

describe '#parseable_version?' do
  it 'should not report emptyness as parseable' do
    expect(Babushka::VersionStr.parseable_version?(nil)).to be_falsey
    expect(Babushka::VersionStr.parseable_version?('')).to be_falsey
    expect(Babushka::VersionStr.parseable_version?('  ')).to be_falsey
  end
  it "should not report digitless input as parseable" do
    expect(Babushka::VersionStr.parseable_version?('nginx')).to be_falsey
  end
  it "should not report input with digits as parseable" do
    expect(Babushka::VersionStr.parseable_version?('3')).to be_truthy
    expect(Babushka::VersionStr.parseable_version?('R13B04')).to be_truthy
    expect(Babushka::VersionStr.parseable_version?('1.9.3-p0')).to be_truthy
  end
end

describe 'rendering' do
  it "should render just the version number with no operator" do
    expect(Babushka::VersionStr.new('0.3.1').to_s).to eq('0.3.1')
  end
  it "should render the full string with an operator" do
    expect(Babushka::VersionStr.new('= 0.3.1').to_s).to eq('0.3.1')
    expect(Babushka::VersionStr.new('== 0.3.1').to_s).to eq('0.3.1')
    expect(Babushka::VersionStr.new('~> 0.3.1').to_s).to eq('~> 0.3.1')
  end
  it "should keep string pieces" do
    expect(Babushka::VersionStr.new('3.0.0.beta').to_s).to eq('3.0.0.beta')
  end
  it "should preserve the original formatting" do
    expect(Babushka::VersionStr.new('1.8.7-p174-src').to_s).to eq('1.8.7-p174-src')
    expect(Babushka::VersionStr.new('3.0.0-beta').to_s).to eq('3.0.0-beta')
  end
end

def compare_with operator
  pairs.zip(results[operator]).each {|pair,expected|
    result = Babushka::VersionStr.new(pair.first).send operator, Babushka::VersionStr.new(pair.last)
    it "#{pair.first} #{operator} #{pair.last}: #{result}" do
      expect(result).to eq(expected)
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
    expect(Babushka::VersionStr.new('0.3.1') <=> nil).to be_nil
  end
end

describe "comparing" do
  it "should work with other VersionStrs" do
    expect(Babushka::VersionStr.new('0.3.1') > Babushka::VersionStr.new('0.2.9')).to be_truthy
  end

  it "should work with strings" do
    expect(Babushka::VersionStr.new('0.3.1') > '0.2.9').to be_truthy
  end

  it "should treat word pieces as less than no piece" do
    expect(Babushka::VersionStr.new('3.0.0') > Babushka::VersionStr.new('3.0.0.beta')).to be_truthy
    expect(Babushka::VersionStr.new('3.0.0') > Babushka::VersionStr.new('3.0.0.beta1')).to be_truthy
    expect(Babushka::VersionStr.new('1.0.0') > Babushka::VersionStr.new('1.0.0.rc.5')).to be_truthy
  end

  it "should compare word pieces alphabetically" do
    expect(Babushka::VersionStr.new('3.0.0.beta') < Babushka::VersionStr.new('3.0.0.pre')).to be_truthy
    expect(Babushka::VersionStr.new('3.0.0.pre') < Babushka::VersionStr.new('3.0.0.rc')).to be_truthy
  end

  it "should treat word pieces with a number as more than without one" do
    expect(Babushka::VersionStr.new('3.0.0.beta1') > Babushka::VersionStr.new('3.0.0.beta')).to be_truthy
  end

  it "should compare number parts of word pieces numerically" do
    expect(Babushka::VersionStr.new('3.0.0.beta2') > Babushka::VersionStr.new('3.0.0.beta1')).to be_truthy
    expect(Babushka::VersionStr.new('3.0.0.beta10') > Babushka::VersionStr.new('3.0.0.beta1')).to be_truthy
  end

  it "should allow for integers in strings and sort correctly" do
    expect(Babushka::VersionStr.new('3.0.0.beta12') > Babushka::VersionStr.new('3.0.0.beta2')).to be_truthy
    expect(Babushka::VersionStr.new('R13B04') > Babushka::VersionStr.new('R2B9')).to be_truthy
  end
end
