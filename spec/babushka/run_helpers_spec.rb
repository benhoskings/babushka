require 'spec_helper'

class RunTester; extend RunHelpers end

describe "grep" do
  it "should grep existing files" do
    RunTester.grep('include', 'spec/spec_helper.rb').should include "include Babushka\n"
  end
  it "should return nil when there are no matches" do
    RunTester.grep('lol', 'spec/spec_helper.rb').should be_nil
  end
  it "should return nil for nonexistent files" do
    RunTester.grep('lol', '/nonexistent').should be_nil
  end
end
