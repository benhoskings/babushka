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

  it "should use default blocks when no specific one is specified" do
    lambda = L{ 'default value' }
    DepDefiner.accepts_block_for :test_defaults, &lambda
    value_from_block = nil
    dep 'default test' do
      value_from_block = test_defaults
    end
    value_from_block.should == lambda
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

describe "#on for filtering accepters" do
  before {
    @lambda = lambda = L{ 'hello from the lambda' }
    dep 'matching' do
      on :osx, met?(&lambda)
    end
  }
  it "should allow choices that match" do
    Dep('matching').send(:payload)[:met?].should == {:osx => @lambda}
  end
  it "should fail when :on is used" do
    L{
      dep 'with :on' do
        on :osx, met?(:on => :osx) { 'bad usage' }
      end
    }.should raise_error("You can't pass the :on option to #met? when you're using it within #on.")
  end
  describe "with non-on calls" do
    before {
      lambda = @lambda
      @all_lambda = all_lambda = L{ 'hello from the lambda' }
      dep 'non-on calls' do
        met? &all_lambda
        on :osx, met?(&lambda)
      end
    }
    it "should move existing unassigned lambdas to all" do
      Dep('non-on calls').send(:payload)[:met?].should == {:osx => @lambda, :all => @all_lambda}
    end
  end
end
