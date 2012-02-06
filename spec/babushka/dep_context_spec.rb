require 'spec_helper'
require 'dep_definer_support'

describe "accepts_block_for behaviour" do
  before {
    Dep.stub!(:base_template).and_return(TestTemplate)
    setup_test_lambdas
    dep 'default'
  }

  it "should define a declarer" do
    Dep('default').context.should_not respond_to(:test_defining)
    TestDepContext.accepts_block_for :test_defining
    Dep('default').context.should respond_to(:test_defining)
  end

  it "should return lambda" do
    TestDepContext.accepts_block_for :test_defining
    lambda = L{ 'blah' }
    value_from_block = nil
    dep 'returning test' do
      value_from_block = test_defining &lambda
    end.met?
    value_from_block.should == lambda
  end

  it "should accept and return a block" do
    test_accepts_block_for_response :test_response, @lambda_hello, @lambda_hello
  end
  it "should accept and return a block for this system" do
    test_accepts_block_for_response :test_this_system, @lambda_hello, @lambda_hello, :on => Base.host.system
  end
  it "should return nothing on a non-specified system" do
    test_accepts_block_for_response :test_other_system, @lambda_hello, nil, :on => :missing
  end

  it "should use default blocks when no specific one is specified" do
    lambda = L{ 'default value' }
    TestDepContext.accepts_block_for :test_defaults, &lambda
    value_from_block = nil
    dep 'default test' do
      value_from_block = test_defaults
    end.met?
    value_from_block.should == lambda
  end

  after { Base.sources.anonymous.deps.clear! }
end

describe "accepts_list_for behaviour" do
  before {
    Babushka::Base.stub!(:host).and_return FakeOSXSystemProfile.new
    make_test_deps
  }
  it "should choose requires for the correct system" do
    Dep('test build tools').context.define!.requires.should == ['xcode tools']
  end
end
