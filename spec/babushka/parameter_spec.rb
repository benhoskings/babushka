require 'spec_helper'

describe Babushka::Parameter do
  it "should not be set without a value" do
    Parameter.new(:test).set?.should be_false
  end
  it "should be set with a value" do
    Parameter.new(:test, 'testy test').set?.should be_true
  end

  describe ".for" do
    let(:input) { 'testy test' }
    let(:param) { Parameter.for(:test, input) }
    it "should return a parameter" do
      param.should be_an_instance_of(Parameter)
    end
    context "with Parameter input" do
      let(:input) { Parameter.new(:test, 'testy test') }
      it "should not re-wrap the Parameter" do
        Parameter.for(:test, input).object_id.should == input.object_id
      end
    end
  end

  describe '#current_value' do
    it "should return the value when the parameter is set" do
      Parameter.for(:value, 'a value').current_value.should == 'a value'
    end
    it "should return nil when the parameter is unset" do
      Parameter.for(:value).current_value.should be_nil
    end
  end

  describe "#==" do
    it "should behave like a string when it's set" do
      Parameter.new(:test, "a value").should == "a value"
      Parameter.new(:test, "a value").should_not == "another value"
    end
    it "should prompt when the value isn't set" do
      Prompt.should_receive(:get_value)
      Parameter.new(:test) == "a value"
    end
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

  describe "#to_a" do
    it "should delegate to the value" do
      Parameter.new(:test, %w[a value]).to_a.should == %w[a value]
    end
    it "should convert non-array values to arrays" do
      Parameter.new(:test, 1..3).to_a.should == [1, 2, 3]
    end
  end

  describe "#to_str" do
    it "should delegate to the value" do
      File.exists?(Parameter.new(:path, "/bin")).should be_true
    end
    it "should fail when the value itself would fail" do
      parameter = Parameter.new(:path, 3065)
      message = if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
        "Coercion error: #<Babushka::Parameter:#{parameter.object_id} path: 3065>.to_str => String failed"
      else
        "Can't coerce 3065:Fixnum into a String"
      end
      L{
        File.exists?(parameter)
      }.should raise_error(TypeError, message)
    end
  end

  describe '#description' do
    it "should describe unset parameters" do
      Parameter.new(:test).description.should == 'test: [unset]'
    end
    it "should describe unset parameters with defaults" do
      Parameter.new(:test).default("a default").description.should == 'test: [default: "a default"]'
    end
    it "should describe unset parameters with bang-defaults" do
      Parameter.new(:test).default!("a bang-default").description.should == 'test: [default!: "a bang-default"]'
    end
    it "should describe set parameters" do
      Parameter.new(:test, "a value").description.should == 'test: "a value"'
    end
    it "should describe non-string values" do
      Parameter.new(:test, %w[non-string value]).description.should == 'test: ["non-string", "value"]'
    end
  end

  describe "other stringy methods" do
    it "should work with #/" do
      (Parameter.new(:test, "/path") / 'joining') == "/path/joining"
    end
    it "should work with #[]" do
      Parameter.new(:test, "The Rural Jurour")[/ur/].should == 'ur'
    end
    it "should work with #p" do
      Parameter.new(:test, "/bin").p.should be_an_instance_of(Fancypath)
    end
  end

  describe "#default!" do
    it "should be returned when no value is set" do
      Parameter.new(:unset).default!('default!').to_s.should == 'default!'
    end
    it "should be ignored when a value is set" do
      Parameter.new(:set, 'value').default!('default!').to_s.should == 'value'
    end
    it "should take precedence over default values" do
      Parameter.new(:unset).default!('default!').default('default').to_s.should == 'default!'
    end
    it "should not set the parameter when returned" do
      Parameter.new(:unset).default!('default!').tap(&:to_s).should_not be_set
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
