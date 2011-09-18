require 'spec_helper'

describe Arg do
  it "should not be set without a value" do
    Arg.new(:test).set?.should be_false
  end
  it "should be set with a value" do
    Arg.new(:test, 'testy test').set?.should be_true
  end
end
