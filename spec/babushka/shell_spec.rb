require 'spec_helper'

describe Shell, '#ok?' do
  it "should return true on success" do
    Shell.new('true', {}).run(&:ok?).should be_true
  end
  it "should return false on failure" do
    Shell.new('false', {}).run(&:ok?).should be_false
  end
end

describe Shell, '#result' do
  it "should return zero on success" do
    Shell.new('true', {}).run(&:result).should == 0
  end
  it "should return non-zero on failure" do
    Shell.new('false', {}).run(&:result).should == 1
  end
end
