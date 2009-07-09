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
  def default_formats
    %w[html xml js json]
  end
  accepts_list_for :records
  accepts_list_for :produces, "a default response"
  accepts_list_for :valid_formats, :default_formats
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

describe "storing" do
  before {
    @list = LambdaListTest.new
  }
  it "should return self to allow chaining" do
    [:records, :produces, :valid_formats].each {|method_name|
      @list.send(method_name, "hello").should == @list
    }
  end
end

describe "returning" do
  before {
    @list = LambdaListTest.new
  }
  it "should return the empty list for no input" do
    @list.records.should == []
  end
  it "should return the correct default when no value is stored" do
    @list.produces.should == ["a default response"]
    @list.valid_formats.should == %w[html xml js json]
  end
  it "should return whatever is stored when called without args" do
    [:records, :produces, :valid_formats].each {|method_name|
      @list.send(method_name, "hello").send(method_name).should == ["hello"]
    }
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
