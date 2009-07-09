require 'spec/spec_support'

class LambdaListTest
  include LambdaList
  attr_reader :payload
  def initialize name = nil
    @name = name
    @payload = {}
  end
  def chooser
    :macports
  end
  accepts_list_for :records
end

describe "invalid input" do
  it "should reject values and a block at once" do
    L{
      LambdaListTest.new.records "stuff" do
        more "stuff"
      end
    }.should raise_error ArgumentError, "You can supply arguments or a block, but not both."
  end
end

describe "returning" do
  before {
    @list = LambdaListTest.new
  }
  it "should return the empty list for no input" do
    LambdaListTest.new.records.should == []
  end
  it "should return whatever is stored when called without args" do
    @list.records "hello"
    @list.records.should == ["hello"]
  end
end

describe "value input" do
  before {
    @test_cases = {
      'a'       => %w[a],
      %w[a]     => %w[a],
      %w[a b c] => %w[a b c],
      {'a' => '0.1', 'b' => '0.2.3'} => {'a' => '0.1', 'b' => '0.2.3'},
    }
  }
  it "should always return a list or hash" do
    @test_cases.each_pair {|input, expected|
      list = LambdaListTest.new
      list.records input
      list.records.should == expected
    }
  end
end

describe "lambda input" do
  before {
    @test_cases = {
      L{ } => [],
      L{
        apt %w[ruby irb ri rdoc]
      } => [],
      L{
        macports 'ruby'
        apt %w[ruby irb ri rdoc]
      } => %w[ruby],
      L{
        macports %w[something else]
        apt %w[some apt packages]
      } => %w[something else]
    }
  }
  it "should return the correct call's args as a list or hash" do
    @test_cases.each_pair {|input, expected|
      list = LambdaListTest.new(input.inspect)
      list.records &input
      list.records.should == expected
    }
  end
end
