require 'spec_helper'
require 'accepts_for_support'

describe "accepts_*_for" do
  subject { AcceptsForTest.new }

  describe "invalid input" do
    it "should reject values and a block at once" do
      L{
        subject.records "stuff" do
          more "stuff"
        end
      }.should raise_error(ArgumentError, "You can supply arguments or a block, but not both.")
    end
  end

  describe "storing" do
    it "should return self to allow chaining" do
      [
        :package, :renders, :format, :records, :produces, :valid_formats
      ].each {|method_name|
        subject.send(method_name, "hello").should == subject
      }
    end
  end

  describe "accepts_value_for" do
    it "should return nil for no input" do
      subject.package.should == nil
    end
    it "should return the correct default when no value is stored" do
      subject.renders.should == "a default response"
      subject.format.should == "json"
    end
    it "should return the value when called without args" do
      [:package, :renders, :format].each {|method_name|
        subject.send(method_name, "hello").send(method_name).should == "hello"
      }
    end
    it "should return the result of callable items" do
      [:package, :renders, :format].each {|method_name|
        subject.send(method_name, L{ "world" }).send(method_name).should == "world"
      }
    end
    it "should replace existing values with new ones" do
      subject.package "ruby-1.8"
      subject.package "ruby-1.9"
      subject.package.should == "ruby-1.9"
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
    it "should return the empty list for no input" do
      subject.records.should == []
    end
    it "should return the empty list for nil input" do
      subject.records nil
      subject.records.should == []
    end
    it "should return the correct default when no value is stored" do
      subject.produces.should == ["a default response"]
      subject.valid_formats.should == %w[html xml js json]
    end
    it "should accept splatted args" do
      subject.records "an item", "another item"
      subject.records.should == ["an item", "another item"]
    end
    it "should accept an array of args" do
      subject.records ["an item", "another item"]
      subject.records.should == ["an item", "another item"]
    end
    it "should return the value when called without args" do
      [:records, :produces, :valid_formats].each {|method_name|
        subject.send(method_name, "hello").send(method_name).should == ["hello"]
      }
    end
    it "should return the result of callable items" do
      [:records, :produces, :valid_formats].each {|method_name|
        subject.send(method_name, "hello", L{ "world" }).send(method_name).should == ["hello", "world"]
      }
    end
    it "should append new values to existing ones" do
      subject.records "scores", "quips"
      subject.records "tall tales"
      subject.records.should == ["scores", "quips", "tall tales"]
    end
  end


  describe "accepts_list_for input processing" do
    describe "value input" do
      test_lists.each_pair {|input, expected|
        it "should return #{expected.inspect} when passed #{input.inspect}" do
          list = AcceptsForTest.new
          list.records input
          list.records.should == expected
        end
      }
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
      test_lists.each_pair {|input, expected|
        it "should return #{expected.inspect} when passed #{input.inspect} within a lambda" do
          l = L{
            via :brew, input
          }
          list = AcceptsForTest.new
          list.records &l
          list.records.should == expected
        end
      }
    end

    describe "nested lambdas" do
      it "should choose recursively" do
        l = L{
          via :brew do
            via :brew, "haha, excellent"
            via :apt, ":|"
          end
          via :apt do
            via :brew, "no, not this one"
            via :apt, "OK this one is just completely wrong"
          end
        }
        list = AcceptsForTest.new
        list.records &l
        list.records.should == ["haha, excellent"]
      end
    end
  end
end
