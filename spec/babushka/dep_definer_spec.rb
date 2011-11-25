require 'spec_helper'
require 'dep_definer_support'

describe "source_template" do
  it "should return BaseTemplate" do
    TestDepContext.source_template.should == Dep::BaseTemplate
  end
end

describe DepDefiner, 'defining' do
  let(:a_dep) { dep('DepDefiner defining spec') }

  it "should return itself" do
    DepDefiner.new(a_dep).tap {|dd|
      dd.define!.should == dd
    }
  end
  it "shouldn't define straight away" do
    DepDefiner.new(a_dep).tap {|dd|
      dd.should_not be_loaded
      dd.should_not be_failed
    }
    DepDefiner.new(a_dep) {}.tap {|dd|
      dd.should_not be_loaded
      dd.should_not be_failed
    }
  end
  it "should define without a block" do
    DepDefiner.new(a_dep).tap {|dd|
      dd.define!
      dd.should be_loaded
      dd.should_not be_failed
    }
  end
  it "should define with a valid block" do
    DepDefiner.new(a_dep) {}.tap {|dd|
      dd.define!
      dd.should be_loaded
      dd.should_not be_failed
    }
  end
  it "should fail with an invalid block" do
    DepDefiner.new(a_dep) { lol }.tap {|dd|
      dd.define!
      dd.should_not be_loaded
      dd.should be_failed
    }
  end
  it "should allow DepDefinitionError to bubble up" do
    lambda {
      DepDefiner.new(a_dep) { raise DepDefinitionError }.define!
    }.should raise_error(DepDefinitionError)
  end
  it "shouldn't define twice" do
    DepDefiner.new(a_dep).tap {|dd|
      dd.should_receive(:define_params!).once
      dd.define!
      dd.define!
    }
  end
end

describe "args" do
  describe "parsing style" do
    it "should parse as named when just a single hash is passed" do
      dep('1 arg', :a).tap {|dep|
        dep.should_receive(:parse_named_arguments).with({:a => 'a'}).and_return({})
        dep.with(:a => 'a')
      }
    end
    it "should parse as a list when non-hash values are passed" do
      dep('2 args', :a, :b).tap {|dep|
        dep.should_receive(:parse_positional_arguments).with(['a', {'key' => 'value'}]).and_return({})
        dep.with('a', 'key' => 'value')
      }
    end
    it "should parse as a list when no args are passed" do
      dep('no args').tap {|dep|
        dep.should_receive(:parse_positional_arguments).with([]).and_return({})
        dep.with
      }
    end
  end
  context "without arguments" do
    it "should fail when called with unnamed args" do
      L{ dep('no args').with('a') }.should raise_error(DepArgumentError, "The dep 'no args' accepts 0 arguments, but 1 was passed.")
    end
    it "should fail when called with named args that don't match" do
      L{ dep('no args').with(:a => 'a') }.should raise_error(DepArgumentError, "The dep 'no args' received an unexpected argument :a.")
    end
  end
  context "with the wrong number of arguments" do
    it "should fail when called with the wrong number of unnamed args" do
      L{ dep('1 arg', :a).with('a', 'b') }.should raise_error(DepArgumentError, "The dep '1 arg' accepts 1 argument, but 2 were passed.")
      L{ dep('2 args', :a, :b).with('a') }.should raise_error(DepArgumentError, "The dep '2 args' accepts 2 arguments, but 1 was passed.")
    end
    it "should fail when called with named args that don't match" do
      L{ dep('1 arg', :a).with(:a => 'a', :b => 'b') }.should raise_error(DepArgumentError, "The dep '1 arg' received an unexpected argument :b.")
      L{ dep('1 arg', :a).with(:a => 'a', :b => 'b', :c => 'c') }.should raise_error(DepArgumentError, "The dep '1 arg' received unexpected arguments :b and :c.")
    end
  end
  context "with empty arguments" do
    subject { dep('2 args', :a, :b).with() }
    it "should populate the args with Parameter objects" do
      subject.args.map_values {|_,v| v.class }.should == {:a => Parameter, :b => Parameter}
    end
    it "should set the names correctly" do
      subject.args.map_values {|_,v| v.name }.should == {:a => :a, :b => :b}
    end
    it "should not set the values" do
      subject.args.values.each {|v| v.should_not be_set }
    end
  end
  context "with the right number of positional arguments" do
    subject { dep('2 args', :a, :b).with('a', 'b') }
    it "should populate the args with Parameter objects" do
      subject.args.map_values {|_,v| v.class }.should == {:a => Parameter, :b => Parameter}
    end
    it "should set the names correctly" do
      subject.args.map_values {|_,v| v.name }.should == {:a => :a, :b => :b}
    end
    it "should set the values" do
      subject.args.values.each {|v| v.should be_set }
    end
  end
  context "with the correct named arguments" do
    subject { dep('2 args', :a, :b).with(:a => 'a', :b => 'b') }
    it "should populate the args with Parameter objects" do
      subject.args.map_values {|_,v| v.class }.should == {:a => Parameter, :b => Parameter}
    end
    it "should set the names correctly" do
      subject.args.map_values {|_,v| v.name }.should == {:a => :a, :b => :b}
    end
    it "should set the values" do
      subject.args.values.each {|v| v.should be_set }
    end
  end
  context "with non-symbol names" do
    it "should be rejected, singular" do
      L{
        dep('2 args', :a).with('a' => 'a')
      }.should raise_error(DepArgumentError, %{The dep '2 args' received a non-symbol argument "a".})
    end
    it "should be rejected, plural" do
      L{
        dep('2 args', :a, :b).with('a' => 'a', 'b' => 'b')
      }.should raise_error(DepArgumentError, %{The dep '2 args' received non-symbol arguments "a" and "b".})
    end
  end
  context "with incomplete named arguments" do
    subject { dep('2 args', :a, :b).with(:a => 'a') }
    it "should partially populate the args with Parameter objects" do
      subject.args.map_values {|_,v| v.class }.should == {:a => Parameter}
    end
    it "should set the names that are present correctly" do
      subject.args.map_values {|_,v| v.name }.should == {:a => :a}
    end
    it "should lazily create the missing parameter" do
      subject.context.b.should be_an_instance_of(Parameter)
      subject.context.b.name.should == :b
    end
    it "should set only the paramters that were passed" do
      subject.context.a.should be_set
      subject.context.b.should_not be_set
    end
  end
end

describe "methods in deps" do
  before {
    dep 'helper method test' do
      def helper_test
        'hello from the helper method!'
      end
    end
    dep 'without helper method'
  }
  it "should only be defined on the specified dep" do
    Dep('helper method test').context.should respond_to(:helper_test)
    Dep('without helper method').context.should_not respond_to(:helper_test)
  end
  it "should return the right value" do
    Dep('helper method test').context.helper_test.should == 'hello from the helper method!'
  end
end

describe "#on for scoping accepters" do
  before {
    Base.stub!(:host).and_return OSXSystemProfile.for_flavour
    Base.host.stub!(:version).and_return '10.6.7'
    @lambda = lambda = L{ 'hello from the lambda' }
    @other_lambda = other_lambda = L{ 'hello from the other lambda' }
    dep 'scoping' do
      on :osx do
        met?(&lambda)
      end
      on :linux do
        met?(&other_lambda)
      end
    end
  }
  it "should only allow choices that match" do
    Dep('scoping').send(:payload)[:met?].should == {:osx => @lambda}
  end
end
