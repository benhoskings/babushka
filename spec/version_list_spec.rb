require 'spec/spec_support'
require 'spec/version_list_support'

describe "invalid input" do
  it "should reject values and a block at once" do
    L{
      VersionListTest.new.records "stuff" do
        more "stuff"
      end
    }.should raise_error ArgumentError, "You can supply arguments or a block, but not both."
  end
end

describe "storing" do
  before {
    @list = VersionListTest.new
  }
  it "should return self to allow chaining" do
    [:records, :produces, :valid_formats].each {|method_name|
      @list.send(method_name, "hello").should == @list
    }
  end
end

describe "returning" do
  before {
    @list = VersionListTest.new
  }
  it "should return the empty list for no input" do
    @list.records.should == []
  end
  it "should return the correct default when no value is stored" do
    @list.produces.should == ["a default response"]
    @list.valid_formats.should == %w[html xml js json]
  end
  it "should return the value when called without args" do
    [:records, :produces, :valid_formats].each {|method_name|
      @list.send(method_name, "hello").send(method_name).should == [ver("hello")]
    }
  end
  it "should append new values to existing ones" do
    @list.records "scores", "quips"
    @list.records "tall tales"
    @list.records.should == [ver("scores"), ver("quips"), ver("tall tales")]
  end
end

describe "value input" do
  it "should always return a [VersionOf] list" do
    test_lists.each_pair {|input, expected|
      list = VersionListTest.new
      list.records input
      list.records.should == expected
    }
  end
end

describe "lambda input" do
  it "should return the correct call's args" do
    test_lambdas.each_pair {|input, expected|
      list = VersionListTest.new(input)
      list.records &input
      list.records.should == expected
    }
  end
  it "should ignore default whenever any lambda is specified" do
    test_lambdas.each_pair {|input, expected|
      list = VersionListTest.new(input)
      list.produces &input
      list.produces.should == expected
    }
  end
end

describe "lambda and value input" do
  it "should return the correct data" do
    test_lists.each_pair {|input, expected|
      l = L{
        macports input
      }
      list = VersionListTest.new
      list.records &l
      list.records.should == expected
    }
  end
end

describe "nested lambdas" do
  it "should choose recursively" do
    l = L{
      macports {
        macports "haha, excellent"
        apt ":|"
      }
      apt {
        macports "no, not this one"
        apt "OK this one is just completely wrong"
      }
    }
    list = VersionListTest.new
    list.records &l
    list.records.should == [ver("haha, excellent")]
  end
end
