require 'spec_helper'

class RunTester; extend RunHelpers end

describe "grep" do
  it "should grep existing files" do
    RunTester.grep('include', 'spec/spec_helper.rb').should include("include Babushka\n")
  end
  it "should return nil when there are no matches" do
    RunTester.grep('lol', 'spec/spec_helper.rb').should be_nil
  end
  it "should return nil for nonexistent files" do
    RunTester.grep('lol', '/nonexistent').should be_nil
  end
end

describe "change_line" do
  path = "#{tmp_prefix}/babushka_run_helper_change_line"
  it "should not mangle a file" do
    File.open(path, "w") { |f| f.write "one\ntwo\nthree\n" }
    RunTester.change_line("two", "changed", path)
    lines = File.open(path, "r") { |f| f.readlines.map{ |l| l.chomp } }
    lines.values_at(0,3,4).should == ["one", "changed", "three"]
    lines.length.should == 5 # two comments added
  end
end
