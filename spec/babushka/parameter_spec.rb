require 'spec_helper'

describe Babushka::Parameter do
  it "should not be set without a value" do
    expect(Babushka::Parameter.new(:test).set?).to be_falsey
  end
  it "should be set with a value" do
    expect(Babushka::Parameter.new(:test, 'testy test').set?).to be_truthy
  end

  describe ".for" do
    let(:input) { 'testy test' }
    let(:param) { Babushka::Parameter.for(:test, input) }
    it "should return a parameter" do
      expect(param).to be_an_instance_of(Babushka::Parameter)
    end
    context "with Parameter input" do
      let(:input) { Babushka::Parameter.new(:test, 'testy test') }
      it "should not re-wrap the Parameter" do
        expect(Babushka::Parameter.for(:test, input).object_id).to eq(input.object_id)
      end
    end
  end

  describe '#current_value' do
    it "should return the value when the parameter is set" do
      expect(Babushka::Parameter.for(:value, 'a value').current_value).to eq('a value')
    end
    it "should return nil when the parameter is unset" do
      expect(Babushka::Parameter.for(:value).current_value).to be_nil
    end
  end

  describe "#==" do
    it "should behave like a string when it's set" do
      expect(Babushka::Parameter.new(:test, "a value")).to eq("a value")
      expect(Babushka::Parameter.new(:test, "a value")).not_to eq("another value")
    end
    it "should prompt when the value isn't set" do
      expect(Babushka::Prompt).to receive(:get_value)
      Babushka::Parameter.new(:test) == "a value"
    end
  end

  describe "#to_s" do
    it "should delegate to the value" do
      expect(Babushka::Parameter.new(:test, "a value").to_s).to eq("a value")
    end
    it "should convert non-string values to strings" do
      expect(Babushka::Parameter.new(:test, 3065).to_s).to eq("3065")
    end
    it "should interpolate" do
      expect("a #{Babushka::Parameter.new(:adjective, "nice")} param").to eq("a nice param")
    end
  end

  describe "#to_a" do
    it "should delegate to the value" do
      expect(Babushka::Parameter.new(:test, %w[a value]).to_a).to eq(%w[a value])
    end
    it "should convert non-array values to arrays" do
      expect(Babushka::Parameter.new(:test, 1..3).to_a).to eq([1, 2, 3])
    end
  end

  describe "#to_str" do
    it "should delegate to the value" do
      expect(File.exists?(Babushka::Parameter.new(:path, "/bin"))).to be_truthy
    end
    it "should fail when the value itself would fail" do
      parameter = Babushka::Parameter.new(:path, 3065)
      message = if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
        "Coercion error: #<Babushka::Parameter:#{parameter.object_id} path: 3065>.to_str => String failed"
      else
        "Can't coerce 3065:Fixnum into a String"
      end
      expect(L{
        File.exists?(parameter)
      }).to raise_error(TypeError, message)
    end
  end

  describe '#description' do
    it "should describe unset parameters" do
      expect(Babushka::Parameter.new(:test).description).to eq('test: [unset]')
    end
    it "should describe unset parameters with defaults" do
      expect(Babushka::Parameter.new(:test).default("a default").description).to eq('test: [default: "a default"]')
    end
    it "should describe unset parameters with bang-defaults" do
      expect(Babushka::Parameter.new(:test).default!("a bang-default").description).to eq('test: [default!: "a bang-default"]')
    end
    it "should describe set parameters" do
      expect(Babushka::Parameter.new(:test, "a value").description).to eq('test: "a value"')
    end
    it "should describe non-string values" do
      expect(Babushka::Parameter.new(:test, %w[non-string value]).description).to eq('test: ["non-string", "value"]')
    end
  end

  describe "other stringy methods" do
    it "should work with #/" do
      (Babushka::Parameter.new(:test, "/path") / 'joining') == "/path/joining"
    end
    it "should work with #[]" do
      expect(Babushka::Parameter.new(:test, "The Rural Jurour")[/ur/]).to eq('ur')
    end
    it "should work with #p" do
      expect(Babushka::Parameter.new(:test, "/bin").p).to be_an_instance_of(Fancypath)
    end
  end

  describe "#default!" do
    it "should be returned when no value is set" do
      expect(Babushka::Parameter.new(:unset).default!('default!').to_s).to eq('default!')
    end
    it "should be ignored when a value is set" do
      expect(Babushka::Parameter.new(:set, 'value').default!('default!').to_s).to eq('value')
    end
    it "should take precedence over default values" do
      expect(Babushka::Parameter.new(:unset).default!('default!').default('default').to_s).to eq('default!')
    end
    it "should not set the parameter when returned" do
      expect(Babushka::Parameter.new(:unset).default!('default!').tap(&:to_s)).not_to be_set
    end
  end

  describe "asking for values" do
    it "should request a value when it's not present" do
      expect(Babushka::Prompt).to receive(:get_value).with('unset', {}).and_return('value')
      expect(Babushka::Parameter.new(:unset).to_s).to eq('value')
    end
    it "should pass the default from #default" do
      expect(Babushka::Prompt).to receive(:get_value).with('unset', :default => 'default').and_return('default')
      expect(Babushka::Parameter.new(:unset).default('default').to_s).to eq('default')
    end
    it "should pass the message from #ask" do
      expect(Babushka::Prompt).to receive(:get_value).with('What number am I thinking of', {}).and_return('7')
      expect(Babushka::Parameter.new(:unset).ask('What number am I thinking of').to_s).to eq('7')
    end
    describe "choices, from #choose" do
      it "should pass to #choices when given as an array" do
        expect(Babushka::Prompt).to receive(:get_value).with('unset', :choices => %w[a b]).and_return('a')
        expect(Babushka::Parameter.new(:unset).choose(%w[a b]).to_s).to eq('a')
      end
      it "should pass to #choices when given as splatted args" do
        expect(Babushka::Prompt).to receive(:get_value).with('unset', :choices => %w[a b]).and_return('a')
        expect(Babushka::Parameter.new(:unset).choose('a', 'b').to_s).to eq('a')
      end
      it "should pass to #choice_descriptions when given as a hash" do
        expect(Babushka::Prompt).to receive(:get_value).with('unset', :choice_descriptions => {:a => 'a', :b => 'b'}).and_return('a')
        expect(Babushka::Parameter.new(:unset).choose(:a => 'a', :b => 'b').to_s).to eq('a')
      end
    end
  end
end
