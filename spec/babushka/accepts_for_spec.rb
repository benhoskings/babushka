require 'spec_helper'
require 'accepts_for_support'

describe "invalid input" do
  it "should reject values and a block at once" do
    L{
      AcceptsForTest.new.records "stuff" do
        more "stuff"
      end
    }.should raise_error(ArgumentError, "You can supply arguments or a block, but not both.")
  end
end

describe "storing" do
  before {
    @list = AcceptsForTest.new
  }
  it "should return self to allow chaining" do
    [
      :package, :renders, :format, :records, :produces, :valid_formats
    ].each {|method_name|
      @list.send(method_name, "hello").should == @list
    }
  end
end

describe "accepts_value_for" do
  before {
    @value = AcceptsForTest.new
  }
  it "should return nil for no input" do
    @value.package.should == nil
  end
  it "should return the correct default when no value is stored" do
    @value.renders.should == "a default response"
    @value.format.should == "json"
  end
  it "should return the value when called without args" do
    [:package, :renders, :format].each {|method_name|
      @value.send(method_name, "hello").send(method_name).should == "hello"
    }
  end
  it "should return the result of callable items" do
    [:package, :renders, :format].each {|method_name|
      @value.send(method_name, L{ "world" }).send(method_name).should == "world"
    }
  end
  it "should replace existing values with new ones" do
    @value.package "ruby-1.8"
    @value.package "ruby-1.9"
    @value.package.should == "ruby-1.9"
  end
end

describe "accepts_value_for input processing" do
  describe "lambda input" do
    it "should return the correct call's args" do
      test_value_lambdas.each_pair {|input, expected|
        value = AcceptsForTest.new(input)
        value.package &input
        value.package.should == expected
      }
    end
    it "should ignore default whenever any lambda is specified" do
      test_value_lambdas.each_pair {|input, expected|
        value = AcceptsForTest.new(input)
        value.renders &input
        value.renders.should == expected
      }
    end
  end
end


describe "accepts_list_for" do
  before {
    @list = AcceptsForTest.new
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
      @list.send(method_name, "hello").send(method_name).should == ["hello"]
    }
  end
  it "should return the result of callable items" do
    [:records, :produces, :valid_formats].each {|method_name|
      @list.send(method_name, "hello", L{ "world" }).send(method_name).should == ["hello", "world"]
    }
  end
  it "should append new values to existing ones" do
    @list.records "scores", "quips"
    @list.records "tall tales"
    @list.records.should == ["scores", "quips", "tall tales"]
  end
end


describe "accepts_list_for input processing" do
  describe "value input" do
    it "should always return a list" do
      test_lists.each_pair {|input, expected|
        list = AcceptsForTest.new
        list.records input
        list.records.should == expected
      }
    end
  end

  describe "lambda input" do
    it "should return the correct call's args" do
      test_list_lambdas.each_pair {|input, expected|
        list = AcceptsForTest.new(input)
        list.records &input
        list.records.should == expected
      }
    end
    it "should ignore default whenever any lambda is specified" do
      test_list_lambdas.each_pair {|input, expected|
        list = AcceptsForTest.new(input)
        list.produces &input
        list.produces.should == expected
      }
    end
  end

  describe "lambda and value input" do
    it "should return the correct data" do
      test_lists.each_pair {|input, expected|
        l = L{
          via :macports, input
        }
        list = AcceptsForTest.new
        list.records &l
        list.records.should == expected
      }
    end
  end

  describe "nested lambdas" do
    it "should choose recursively" do
      l = L{
        via :macports do
          via :macports, "haha, excellent"
          via :apt, ":|"
        end
        via :apt do
          via :macports, "no, not this one"
          via :apt, "OK this one is just completely wrong"
        end
      }
      list = AcceptsForTest.new
      list.records &l
      list.records.should == ["haha, excellent"]
    end
  end
end


describe "accepts_versions_for input processing" do
  it "should always return a [VersionOf] list" do
    test_versions.each_pair {|input, expected|
      versions = AcceptsForTest.new
      versions.installs input
      versions.installs.should == expected
    }
  end
end
