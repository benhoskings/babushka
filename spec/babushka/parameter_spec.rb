require 'spec_helper'

describe Parameter do
  it "should not be set without a value" do
    Parameter.new(:test).set?.should be_false
  end
  it "should be set with a value" do
    Parameter.new(:test, 'testy test').set?.should be_true
  end

  describe "#to_s" do
    it "should delegate to the value" do
      Parameter.new(:test, "a value").to_s.should == "a value"
    end
    it "should convert non-string values to strings" do
      Parameter.new(:test, 3065).to_s.should == "3065"
    end
    it "should interpolate" do
      "a #{Parameter.new(:adjective, "nice")} param".should == "a nice param"
    end
  end

  describe "#to_str" do
    it "should delegate to the value" do
      File.exists?(Parameter.new(:path, "/bin")).should be_true
    end
    it "should fail when the value itself would fail" do
      L{
        File.exists?(Parameter.new(:path, 3065))
      }.should raise_error(DepArgumentError, "Can't coerce 3065:Fixnum into a String")
    end
  end

  describe "asking for values" do
    it "should request a value when it's not present" do
      Prompt.should_receive(:get_value).with('unset', {}).and_return('value')
      Parameter.new(:unset).to_s.should == 'value'
    end
    it "should pass the default from #default" do
      Prompt.should_receive(:get_value).with('unset', :default => 'default').and_return('default')
      Parameter.new(:unset).default('default').to_s.should == 'default'
    end
    it "should pass the message from #ask" do
      Prompt.should_receive(:get_value).with('What number am I thinking of', {}).and_return('7')
      Parameter.new(:unset).ask('What number am I thinking of').to_s.should == '7'
    end
    describe "choices, from #choose" do
      it "should pass to #choices when given as an array" do
        Prompt.should_receive(:get_value).with('unset', :choices => %w[a b]).and_return('a')
        Parameter.new(:unset).choose(%w[a b]).to_s.should == 'a'
      end
      it "should pass to #choices when given as splatted args" do
        Prompt.should_receive(:get_value).with('unset', :choices => %w[a b]).and_return('a')
        Parameter.new(:unset).choose('a', 'b').to_s.should == 'a'
      end
      it "should pass to #choice_descriptions when given as a hash" do
        Prompt.should_receive(:get_value).with('unset', :choice_descriptions => {:a => 'a', :b => 'b'}).and_return('a')
        Parameter.new(:unset).choose(:a => 'a', :b => 'b').to_s.should == 'a'
      end
    end
  end
end
