require 'spec_helper'

RSpec.describe "source_template" do
  it "should be base_template" do
    expect(Babushka::DepContext.source_template).to eq(Babushka::Dep.base_template)
  end
end

RSpec.describe Babushka::DepDefiner, '#define!' do
  let(:a_dep) { dep('DepDefiner defining spec') }

  it "should return itself" do
    Babushka::DepDefiner.new(a_dep).tap {|dd|
      expect(dd.define!).to eq(dd)
    }
  end
  it "shouldn't define straight away" do
    Babushka::DepDefiner.new(a_dep).tap {|dd|
      expect(dd).not_to be_loaded
      expect(dd).not_to be_failed
    }
    Babushka::DepDefiner.new(a_dep) {}.tap {|dd|
      expect(dd).not_to be_loaded
      expect(dd).not_to be_failed
    }
  end
  it "should define without a block" do
    Babushka::DepDefiner.new(a_dep).tap {|dd|
      dd.define!
      expect(dd).to be_loaded
      expect(dd).not_to be_failed
    }
  end
  it "should define with a valid block" do
    Babushka::DepDefiner.new(a_dep) {}.tap {|dd|
      dd.define!
      expect(dd).to be_loaded
      expect(dd).not_to be_failed
    }
  end
  it "should fail with an invalid block" do
    Babushka::DepDefiner.new(a_dep) { lol }.tap {|dd|
      expect { dd.define! }.to raise_error(NameError, /undefined local variable or method `lol'/)
      expect(dd).not_to be_loaded
      expect(dd).to be_failed
    }
  end
  it "shouldn't define twice" do
    Babushka::DepDefiner.new(a_dep).tap {|dd|
      expect(dd).to receive(:define_elements!).once
      dd.define!
      dd.define!
    }
  end
  it "should allow DepDefinitionError to bubble up" do
    expect {
      Babushka::DepDefiner.new(a_dep) { raise Babushka::DepDefinitionError }.define!
    }.to raise_error(Babushka::DepDefinitionError)
  end
  it "shouldn't attempt re-defining after failure" do
    Babushka::DepDefiner.new(a_dep).tap {|dd|
      allow(dd).to receive(:failed?).and_return(true)
      expect(dd).not_to receive(:define_elements!)
    }.define!
  end
end

RSpec.describe Babushka::DepDefiner, '#invoke' do
  let(:a_dep) { dep('DepDefiner invoking spec') }
  let(:definer) { Babushka::DepDefiner.new(a_dep) }

  it "should define and invoke when undefined" do
    expect(definer).to receive(:define!)
    expect(definer).to receive(:met?).and_return(lambda {|_| })
    definer.invoke(:met?)
  end

  it "should invoke only when already defined" do
    allow(definer).to receive(:loaded?).and_return(true)
    expect(definer).not_to receive(:define!)
    expect(definer).to receive(:met?).and_return(lambda {|_| })
    definer.invoke(:met?)
  end

  it "should not invoke when defining failed" do
    expect(definer).to receive(:define_elements!).and_raise("expected error")
    expect(definer).not_to receive(:met?)
    expect { definer.invoke(:met?) }.to raise_error("expected error")
  end

  it "should call the task with a valid block" do
    expect(Babushka::DepContext.new(a_dep) { }.invoke(:met?)).to be_truthy
    expect(Babushka::DepContext.new(a_dep) { met? { false } }.invoke(:met?)).to be_falsey
  end
end

RSpec.describe "args" do
  describe "parsing style" do
    it "should parse as named when just a single hash is passed" do
      dep('1 arg', :a).tap {|dep|
        expect(dep).to receive(:parse_named_arguments).with({:a => 'a'}).and_return({})
        dep.with(:a => 'a')
      }
    end
    it "should parse as a list when non-hash values are passed" do
      dep('2 args', :a, :b).tap {|dep|
        expect(dep).to receive(:parse_positional_arguments).with(['a', {'key' => 'value'}]).and_return({})
        dep.with('a', 'key' => 'value')
      }
    end
    it "should parse as a list when no args are passed" do
      dep('no args').tap {|dep|
        expect(dep).to receive(:parse_positional_arguments).with([]).and_return({})
        dep.with
      }
    end
  end
  context "without arguments" do
    it "should fail when called with unnamed args" do
      expect(L{ dep('no args').with('a') }).to raise_error(Babushka::DepArgumentError, "The dep 'no args' accepts 0 arguments, but 1 was passed.")
    end
    it "should fail when called with named args that don't match" do
      expect(L{ dep('no args').with(:a => 'a') }).to raise_error(Babushka::DepArgumentError, "The dep 'no args' received an unexpected argument :a.")
    end
  end
  context "with the wrong number of arguments" do
    it "should fail when called with the wrong number of unnamed args" do
      expect(L{ dep('1 arg', :a).with('a', 'b') }).to raise_error(Babushka::DepArgumentError, "The dep '1 arg' accepts 1 argument, but 2 were passed.")
      expect(L{ dep('2 args', :a, :b).with('a') }).to raise_error(Babushka::DepArgumentError, "The dep '2 args' accepts 2 arguments, but 1 was passed.")
    end
    it "should fail when called with named args that don't match" do
      expect(L{ dep('1 arg', :a).with(:a => 'a', :b => 'b') }).to raise_error(Babushka::DepArgumentError, "The dep '1 arg' received an unexpected argument :b.")
      expect(L{ dep('1 arg', :a).with(:a => 'a', :b => 'b', :c => 'c') }).to raise_error(Babushka::DepArgumentError, "The dep '1 arg' received unexpected arguments :b and :c.")
    end
  end
  context "with empty arguments" do
    subject { dep('2 args', :a, :b).with() }
    it "should populate the args with Parameter objects" do
      expect(subject.args.map_values {|_,v| v.class }).to eq({:a => Babushka::Parameter, :b => Babushka::Parameter})
    end
    it "should set the names correctly" do
      expect(subject.args.map_values {|_,v| v.name }).to eq({:a => :a, :b => :b})
    end
    it "should not set the values" do
      subject.args.values.each {|v| expect(v).not_to be_set }
    end
  end
  context "with the right number of positional arguments" do
    subject { dep('2 args', :a, :b).with('a', 'b') }
    it "should populate the args with Parameter objects" do
      expect(subject.args.map_values {|_,v| v.class }).to eq({:a => Babushka::Parameter, :b => Babushka::Parameter})
    end
    it "should set the names correctly" do
      expect(subject.args.map_values {|_,v| v.name }).to eq({:a => :a, :b => :b})
    end
    it "should set the values" do
      subject.args.values.each {|v| expect(v).to be_set }
    end
  end
  context "with the correct named arguments" do
    subject { dep('2 args', :a, :b).with(:a => 'a', :b => 'b') }
    it "should populate the args with Parameter objects" do
      expect(subject.args.map_values {|_,v| v.class }).to eq({:a => Babushka::Parameter, :b => Babushka::Parameter})
    end
    it "should set the names correctly" do
      expect(subject.args.map_values {|_,v| v.name }).to eq({:a => :a, :b => :b})
    end
    it "should set the values" do
      subject.args.values.each {|v| expect(v).to be_set }
    end
  end
  context "with non-symbol names" do
    it "should be rejected, singular" do
      expect(L{
        dep('2 args', :a).with('a' => 'a')
      }).to raise_error(Babushka::DepArgumentError, %{The dep '2 args' received a non-symbol argument "a".})
    end
    it "should be rejected, plural" do
      expect(L{
        dep('2 args', :a, :b).with('a' => 'a', 'b' => 'b')
      }).to raise_error(Babushka::DepArgumentError, %{The dep '2 args' received non-symbol arguments "a" and "b".})
    end
  end
  context "with incomplete named arguments" do
    subject { dep('2 args', :a, :b).with(:a => 'a') }
    it "should partially populate the args with Parameter objects" do
      expect(subject.args.map_values {|_,v| v.class }).to eq({:a => Babushka::Parameter})
    end
    it "should set the names that are present correctly" do
      expect(subject.args.map_values {|_,v| v.name }).to eq({:a => :a})
    end
    it "should lazily create the missing parameter" do
      expect(subject.context.define!.b).to be_an_instance_of(Babushka::Parameter)
      expect(subject.context.define!.b.name).to eq(:b)
    end
    it "should set only the paramters that were passed" do
      expect(subject.context.define!.a).to be_set
      expect(subject.context.define!.b).not_to be_set
    end
  end
end

RSpec.describe "methods in deps" do
  before {
    dep 'helper method test' do
      def helper_test
        'hello from the helper method!'
      end
    end
    dep 'without helper method'
  }
  it "should only be defined on the specified dep" do
    expect(Dep('helper method test').context.define!).to respond_to(:helper_test)
    expect(Dep('without helper method').context.define!).not_to respond_to(:helper_test)
  end
  it "should return the right value" do
    expect(Dep('helper method test').context.define!.helper_test).to eq('hello from the helper method!')
  end
end

RSpec.describe "#on for scoping accepters" do
  let!(:the_lambda) { L{ 'hello from the lambda' } }
  let!(:other_lambda) { L{ 'hello from the other lambda' } }
  before {
    allow(Babushka).to receive(:host).and_return(Babushka::OSXSystemProfile.new)
    allow(Babushka.host).to receive(:match_list).and_return([:osx])

    local_lambda, other_local_lambda = the_lambda, other_lambda

    dep 'scoping' do
      on :osx do
        met?(&local_lambda)
      end
      on :linux do
        met?(&other_local_lambda)
      end
    end
  }
  it "should only allow choices that match" do
    expect(Dep('scoping').tap {|dep|
      dep.context.define!
    }.context.payload[:met?]).to eq({:osx => the_lambda})
  end
end
