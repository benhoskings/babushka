require 'spec_helper'

describe '#ssh' do
  it "should return a Babushka::SSH instance" do
    value = nil
    dep 'ssh test without block' do
      value = ssh('user@host')
    end.met?
    value.should be_an_instance_of(Babushka::SSH)
    value.host.should == 'user@host'
  end
  it "should yield the Babushka::SSH instance to the block" do
    value = nil
    dep 'ssh test with block' do
      ssh('user@host') {|remote|
        value = remote
      }
    end.met?
    value.should be_an_instance_of(Babushka::SSH)
    value.host.should == 'user@host'
  end
end

describe "accepts_block_for behaviour" do
  let(:lambda_hello) { L{ "hello world!" } }

  def test_accepts_block_for_response accepter_name, lambda, value, opts = {}
    DepContext.accepts_block_for accepter_name
    dep 'accepts_block_for' do
      send accepter_name, opts, &lambda
    end
    on = opts[:on].nil? ? :all : Babushka.host.system
    Dep('accepts_block_for').context.define!.payload[accepter_name][on].should == value
  end

  before {
    Babushka.host.stub(:match_list).and_return([:osx])
    dep 'default'
  }

  it "should define a declarer" do
    Dep('default').context.should_not respond_to(:test_defining)
    DepContext.accepts_block_for :test_defining
    Dep('default').context.should respond_to(:test_defining)
  end

  it "should return lambda" do
    DepContext.accepts_block_for :test_defining
    lambda = L{ 'blah' }
    value_from_block = nil
    dep 'returning test' do
      value_from_block = test_defining(&lambda)
    end.met?
    value_from_block.should == lambda
  end

  it "should accept and return a block" do
    test_accepts_block_for_response :test_response, lambda_hello, lambda_hello
  end
  it "should accept and return a block for this system" do
    test_accepts_block_for_response :test_this_system, lambda_hello, lambda_hello, :on => Babushka.host.system
  end
  it "should return nothing on a non-specified system" do
    test_accepts_block_for_response :test_other_system, lambda_hello, nil, :on => :missing
  end

  it "should use default blocks when no specific one is specified" do
    lambda = L{ 'default value' }
    DepContext.accepts_block_for :test_defaults, &lambda
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
    Babushka.host.stub(:match_list).and_return([:osx])
    dep 'test build tools' do
      requires {
        on :osx, 'xcode tools'
        on :linux, 'build-essential', 'autoconf'
      }
    end
  }
  it "should choose requires for the correct system" do
    Dep('test build tools').context.define!.requires.should == ['xcode tools']
  end
end
