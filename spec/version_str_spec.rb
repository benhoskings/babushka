require 'spec/spec_support'
require 'spec/version_str_support'

def compare_with operator
  pairs.zip(results[operator]).each {|pair,expected|
    result = VersionStr.new(pair.first).send operator, VersionStr.new(pair.last)
    it "#{pair.first} #{operator} #{pair.last}: #{result}" do
      expected.should == result
    end
  }
end

%w[== != > < >= <= ~>].each do |operator|
  describe operator do
    compare_with operator
  end
end

describe "parsing" do
  it "should parse the version number" do
    VersionStr.new('0.2').pieces.should == [0, 2]
    VersionStr.new('0.3.10.2').pieces.should == [0, 3, 10, 2]
  end
  it "should parse the operator if supplied" do
    v = VersionStr.new('= 0.2')
    v.pieces.should == [0, 2]
    v.operator.should == '='

    v = VersionStr.new('~>  0.3.10.2')
    v.pieces.should == [0, 3, 10, 2]
    v.operator.should == '~>'
  end
end
