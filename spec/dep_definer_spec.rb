require 'spec/spec_support'
require 'spec/dep_definer_support'

describe "loading deps" do
  it "should load deps from a file" do
    DepDefiner.load_deps_from('spec/deps/good').should be_true
    Dep.names.should include('test dep 1')
  end
  it "should recover from load errors" do
    DepDefiner.load_deps_from('spec/deps/bad').should be_nil
    Dep.names.should_not include('broken test dep 1')
  end
end

describe "accepts_block_for behaviour" do
  before {
    setup_test_lambdas
    dep 'default'
  }

  it "should define a declarer" do
    Dep('default').definer.should_not respond_to :test_defining
    DepDefiner.accepts_block_for :test_defining
    Dep('default').definer.should respond_to :test_defining
  end

  it "should return [method_name, lambda]" do
    DepDefiner.accepts_block_for :test_defining
    lambda = L{ 'blah' }
    value_from_block = nil
    dep 'returning test' do
      value_from_block = test_defining &lambda
    end
    value_from_block.should == [:test_defining, lambda]
  end

  it "should accept and return a block" do
    test_accepts_block_for_response :test_response, @lambda_hello, @lambda_hello
  end
  it "should accept and return a block for this system" do
    test_accepts_block_for_response :test_this_system, @lambda_hello, @lambda_hello, :on => host.system
  end
  it "should return nothing on a non-specified system" do
    test_accepts_block_for_response :test_other_system, @lambda_hello, nil, :on => :nonexistent
  end

  after { Dep.clear! }
end

describe "accepts_list_for behaviour" do
  before {
    make_test_deps
  }
  it "should choose requires for the correct system" do
    Dep('build tools').definer.requires.should == [ver('xcode tools')]
  end
end
