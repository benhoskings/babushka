require 'spec_helper'
require 'accepts_for_support'

RSpec.describe "accepts_*_for" do
  subject { AcceptsForTest.new }

  describe "invalid input" do
    it "should reject values and a block at once" do
      expect {
        subject.records "stuff" do
          more "stuff"
        end
      }.to raise_error(ArgumentError, "You can supply arguments or a block, but not both.")
    end
  end

  describe "storing" do
    it "should return self to allow chaining" do
      [
        :package, :renders, :format, :records, :produces, :valid_formats
      ].each {|method_name|
        expect(subject.send(method_name, "hello")).to eq(subject)
      }
    end
  end

  describe "accepts_value_for" do
    it "should return nil for no input" do
      expect(subject.package).to eq(nil)
    end
    it "should return the correct default when no value is stored" do
      expect(subject.renders).to eq("a default response")
      expect(subject.format).to eq("json")
    end
    it "should handle boolean defaults correctly" do
      expect(subject.do_cleanup).to eq(false)
      expect(subject.do_backup).to eq(true)
    end
    it "should return the value when called without args" do
      [:package, :renders, :format].each {|method_name|
        expect(subject.send(method_name, "hello").send(method_name)).to eq("hello")
      }
    end
    it "should return the result of callable items" do
      [:package, :renders, :format].each {|method_name|
        expect(subject.send(method_name, lambda{ "world" }).send(method_name)).to eq("world")
      }
    end
    it "should replace existing values with new ones" do
      subject.package "ruby-1.8"
      subject.package "ruby-1.9"
      expect(subject.package).to eq("ruby-1.9")
    end
  end

  describe "accepts_value_for input processing" do
    describe "lambda input" do
      it "should return the correct call's args" do
        test_value_lambdas.each_pair {|input, expected|
          value = AcceptsForTest.new(input)
          value.package &input
          expect(value.package).to eq(expected)
        }
      end
      it "should ignore default whenever any lambda is specified" do
        test_value_lambdas.each_pair {|input, expected|
          value = AcceptsForTest.new(input)
          value.renders &input
          expect(value.renders).to eq(expected)
        }
      end
    end
  end


  describe "accepts_list_for" do
    it "should return the empty list for no input" do
      expect(subject.records).to eq([])
    end
    it "should return the empty list for nil input" do
      subject.records nil
      expect(subject.records).to eq([])
    end
    it "should return the correct default when no value is stored" do
      expect(subject.produces).to eq(["a default response"])
      expect(subject.valid_formats).to eq(%w[html xml js json])
    end
    it "should accept splatted args" do
      subject.records "an item", "another item"
      expect(subject.records).to eq(["an item", "another item"])
    end
    it "should accept an array of args" do
      subject.records ["an item", "another item"]
      expect(subject.records).to eq(["an item", "another item"])
    end
    it "should return the value when called without args" do
      [:records, :produces, :valid_formats].each {|method_name|
        expect(subject.send(method_name, "hello").send(method_name)).to eq(["hello"])
      }
    end
    it "should return the result of callable items" do
      [:records, :produces, :valid_formats].each {|method_name|
        expect(subject.send(method_name, "hello", lambda{ "world" }).send(method_name)).to eq(["hello", "world"])
      }
    end
    it "should append new values to existing ones" do
      subject.records "scores", "quips"
      subject.records "tall tales"
      expect(subject.records).to eq(["scores", "quips", "tall tales"])
    end
  end


  describe "accepts_list_for input processing" do
    describe "value input" do
      test_lists.each_pair {|input, expected|
        it "should return #{expected.inspect} when passed #{input.inspect}" do
          list = AcceptsForTest.new
          list.records input
          expect(list.records).to eq(expected)
        end
      }
    end

    describe "lambda input" do
      it "should return the correct call's args" do
        test_list_lambdas.each_pair {|input, expected|
          list = AcceptsForTest.new(input)
          list.records &input
          expect(list.records).to eq(expected)
        }
      end
      it "should ignore default whenever any lambda is specified" do
        test_list_lambdas.each_pair {|input, expected|
          list = AcceptsForTest.new(input)
          list.produces &input
          expect(list.produces).to eq(expected)
        }
      end
    end

    describe "lambda and value input" do
      test_lists.each_pair {|input, expected|
        it "should return #{expected.inspect} when passed #{input.inspect} within a lambda" do
          l = proc{
            via :brew, input
          }
          list = AcceptsForTest.new
          list.records &l
          expect(list.records).to eq(expected)
        end
      }
    end

    describe "nested lambdas" do
      it "should choose recursively" do
        l = proc{
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
        expect(list.records).to eq(["haha, excellent"])
      end
    end
  end
end
