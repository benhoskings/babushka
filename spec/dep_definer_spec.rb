require 'spec/spec_support'
require 'spec/dep_definer_support'

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

  it "should accept and return a block" do
    test_accepts_block_for_response :test_response, @lambda_hello, @lambda_hello
  end
  it "should accept and return a block for this system" do
    test_accepts_block_for_response :test_this_system, @lambda_hello, @lambda_hello, :on => uname
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
