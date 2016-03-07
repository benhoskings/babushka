require 'spec_helper'

RSpec.describe '#ssh' do
  it "should return a Babushka::SSH instance" do
    value = nil
    dep 'ssh test without block' do
      value = ssh('user@host')
    end.met?
    expect(value).to be_an_instance_of(Babushka::SSH)
    expect(value.host).to eq('user@host')
  end
  it "should yield the Babushka::SSH instance to the block" do
    value = nil
    dep 'ssh test with block' do
      ssh('user@host') {|remote|
        value = remote
      }
    end.met?
    expect(value).to be_an_instance_of(Babushka::SSH)
    expect(value.host).to eq('user@host')
  end
end

RSpec.describe "accepts_block_for behaviour" do
  let(:lambda_hello) { L{ "hello world!" } }

  def test_accepts_block_for_response accepter_name, lambda, value, opts = {}
    Babushka::DepContext.accepts_block_for accepter_name
    dep 'accepts_block_for' do
      send accepter_name, opts, &lambda
    end
    on = opts[:on].nil? ? :all : Babushka.host.system
    expect(Dep('accepts_block_for').context.define!.payload[accepter_name][on]).to eq(value)
  end

  before {
    allow(Babushka.host).to receive(:match_list).and_return([:osx])
    dep 'default'
  }

  it "should define a declarer" do
    expect(Dep('default').context).not_to respond_to(:test_defining)
    Babushka::DepContext.accepts_block_for :test_defining
    expect(Dep('default').context).to respond_to(:test_defining)
  end

  it "should return lambda" do
    Babushka::DepContext.accepts_block_for :test_defining
    lambda = L{ 'blah' }
    value_from_block = nil
    dep 'returning test' do
      value_from_block = test_defining(&lambda)
    end.met?
    expect(value_from_block).to eq(lambda)
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
    Babushka::DepContext.accepts_block_for :test_defaults, &lambda
    value_from_block = nil
    dep 'default test' do
      value_from_block = test_defaults
    end.met?
    expect(value_from_block).to eq(lambda)
  end

  after { Babushka::Base.sources.anonymous.deps.clear! }
end

RSpec.describe "accepts_list_for behaviour" do
  before {
    allow(Babushka.host).to receive(:match_list).and_return([:osx])
    dep 'test build tools' do
      requires {
        on :osx, 'xcode tools'
        on :linux, 'build-essential', 'autoconf'
      }
    end
  }
  it "should choose requires for the correct system" do
    expect(Dep('test build tools').context.define!.requires).to eq(['xcode tools'])
  end
end
