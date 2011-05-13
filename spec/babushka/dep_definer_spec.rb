require 'spec_helper'
require 'dep_definer_support'

describe "source_template" do
  it "should return BaseTemplate" do
    TestDepContext.source_template.should == Dep::BaseTemplate
  end
end

describe "args" do
  it "should raise when the wrong number of args are supplied" do
    L{ dep('arg arity 1') {|a| }.context.define! }.should raise_error(DepArgumentError, "The dep 'arg arity 1' requires 1 argument, but 0 were passed.")
    L{ dep('arg arity 2') {|a,b| }.with('a').context.define! }.should raise_error(DepArgumentError, "The dep 'arg arity 2' requires 2 arguments, but 1 was passed.")
    L{ dep('arg arity 3') {|a| }.with('a', 'b').context.define! }.should raise_error(DepArgumentError, "The dep 'arg arity 3' requires 1 argument, but 2 were passed.")
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
