require 'spec_helper'
require 'dep_definer_support'

describe "accepts_block_for behaviour" do
  before {
    Dep.stub!(:base_template).and_return(TestTemplate)
    setup_test_lambdas
    dep 'default'
  }

  it "should define a declarer" do
    Dep('default').definer.should_not respond_to(:test_defining)
    TestDepDefiner.accepts_block_for :test_defining
    Dep('default').definer.should respond_to(:test_defining)
  end

  it "should return lambda" do
    TestDepDefiner.accepts_block_for :test_defining
    lambda = L{ 'blah' }
    value_from_block = nil
    dep 'returning test' do
      value_from_block = test_defining &lambda
    end
    value_from_block.should == lambda
  end

  it "should accept and return a block" do
    test_accepts_block_for_response :test_response, @lambda_hello, @lambda_hello
  end
  it "should accept and return a block for this system" do
    test_accepts_block_for_response :test_this_system, @lambda_hello, @lambda_hello, :on => Base.host.system
  end
  it "should return nothing on a non-specified system" do
    test_accepts_block_for_response :test_other_system, @lambda_hello, nil, :on => :nonexistent
  end

  it "should use default blocks when no specific one is specified" do
    lambda = L{ 'default value' }
    TestDepDefiner.accepts_block_for :test_defaults, &lambda
    value_from_block = nil
    dep 'default test' do
      value_from_block = test_defaults
    end
    value_from_block.should == lambda
  end

  after { Base.sources.anonymous.deps.clear! }
end

describe "source_template" do
  it "should return BaseTemplate" do
    TestDepDefiner.source_template.should == Dep::BaseTemplate
  end
end

describe "helper" do
  before {
    dep 'helper test' do
      helper :helper_test do
        'hello from the helper!'
      end
    end
    dep 'another test'
  }
  it "should only define the helper on the specified dep" do
    Dep('helper test').definer.should respond_to(:helper_test)
    Dep('another test').definer.should_not respond_to(:helper_test)
  end
  it "should respond to the helper" do
    Dep('helper test').definer.helper_test.should == 'hello from the helper!'
  end
end

describe "helper with args" do
  before {
    dep 'helper args test' do
      helper :helper_args_test do |message,punct|
        "#{message} from the helper#{punct}"
      end
    end
  }
  it "should respond to the helper including the args" do
    Dep('helper args test').definer.helper_args_test('salut', ' :)').should == 'salut from the helper :)'
  end
  it "should fail with the wrong number of args" do
    L{
      Dep('helper args test').definer.helper_args_test('salut')
    }.should raise_error(ArgumentError, "wrong number of args to helper_args_test (1 for 2)")
  end
end

describe "helper with splatted args" do
  before {
    dep 'helper splatted args test' do
      helper :helper_splatted_args_test do |*args|
        "#{args.join(', ')} from the helper!"
      end
    end
  }
  it "should respond to the helper including the args" do
    Dep('helper splatted args test').definer.helper_splatted_args_test('salut', 'bonjour', "g'day").should == "salut, bonjour, g'day from the helper!"
  end
end

describe "accepts_list_for behaviour" do
  before {
    make_test_deps
  }
  it "should choose requires for the correct system" do
    Dep('test build tools').definer.requires.should == ['xcode tools']
  end
end

describe "#on for scoping accepters" do
  before {
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
