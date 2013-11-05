require 'spec_helper'
require 'timeout'

describe Babushka::Shell, "arguments" do
  it "should reject calls with no arguments, since exec will explode anyway" do
    L{ Babushka::Shell.new }.should raise_error(ArgumentError, "wrong number of arguments (0 for 1+)")
  end
end

describe Babushka::Shell, '#ok?' do
  it "should return true on success" do
    Babushka::Shell.new('true', {}).run(&:ok?).should be_true
  end
  it "should return false on failure" do
    Babushka::Shell.new('false', {}).run(&:ok?).should be_false
  end
end

describe Babushka::Shell, '#result' do
  it "should return zero on success" do
    Babushka::Shell.new('true', {}).run(&:result).should == 0
  end
  it "should return non-zero on failure" do
    Babushka::Shell.new('false', {}).run(&:result).should == 1
  end
end

describe Babushka::Shell do
  it "should close stdin, so subprocesses don't wait for input forever" do
    Timeout::timeout(1) do
      Babushka::Shell.new('cat', {}).run(&:result).should == 0
    end
  end
end
