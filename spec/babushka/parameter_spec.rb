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
      }.should raise_error(NoMethodError, "undefined method `to_str' for 3065:Fixnum")
    end
  end

  describe "asking for values" do
    it "should request a value when it's not present" do
      Prompt.should_receive(:get_value).with('unset', :default => nil).and_return('value')
      Parameter.new(:unset).to_s.should == 'value'
    end
    describe "with defaults" do
      it "should return the default" do
        Prompt.should_receive(:get_value).with('unset', :default => 'default').and_return('default')
        Parameter.new(:unset).default('default').to_s.should == 'default'
      end
    end
  end
end
