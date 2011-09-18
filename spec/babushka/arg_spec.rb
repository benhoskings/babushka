require 'spec_helper'

describe Arg do
  it "should not be set without a value" do
    Arg.new(:test).set?.should be_false
  end
  it "should be set with a value" do
    Arg.new(:test, 'testy test').set?.should be_true
  end

  describe "#to_s" do
    it "should delegate to the value" do
      Arg.new(:test, "a value").to_s.should == "a value"
    end
    it "should convert non-string values to strings" do
      Arg.new(:test, 3065).to_s.should == "3065"
    end
    it "should interpolate" do
      "a #{Arg.new(:adjective, "nice")} arg".should == "a nice arg"
    end
  end
end
