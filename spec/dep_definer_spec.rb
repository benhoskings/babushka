require 'spec/spec_support'
require 'spec/dep_definer_support'

def test_accepts_block_for_response accepter_name, lambda, value, opts = nil
  DepDefiner.accepts_block_for accepter_name
  dep 'accepts_block_for' do
    if opts.nil?
      send accepter_name, &lambda
    else
      send accepter_name, opts, &lambda
    end
  end
  Dep('accepts_block_for').definer.send(accepter_name).should == value
end

describe "accepts_block_for basics" do
  before {
    setup_test_deps
    setup_test_lambdas
  }

  it "should define a declarer" do
    Dep('default').definer.should_not respond_to :test_defining
    DepDefiner.accepts_block_for :test_defining
    Dep('default').definer.should respond_to :test_defining
  end

  it "should accept and return a block a declarer" do
    test_accepts_block_for_response :test_response, @lambda_hello, @lambda_hello
  end
  it "should accept and return a block a declarer for this system" do
    test_accepts_block_for_response :test_this_system, @lambda_hello, @lambda_hello, :on => uname
  end
  it "should return nothing on a non-specified system" do
    test_accepts_block_for_response :test_other_system, @lambda_hello, nil, :on => :nonexistent
  end

  after { Dep.clear! }
end


describe "accepts_hash_for resultant values" do
  before {
    @deps_to_make = {
      'single' => 'a',
      'array of one' => %w[a],
      'array of multiple' => %w[a b c],
      'all, singles' => {:all => 'a'},
      'all, array of one' => {:all => %w[a]},
      'all, array of multiple' => {:all => %w[a b c]},
      'osx, singles' => {:osx => 'a'},
      'osx, array of one' => {:osx => %w[a]},
      'osx, array of multiple' => {:osx => %w[a b c]}
    }

    @deps_to_make.each {|name,require_value|
      dep name do
        requires require_value
      end
    }
  }

  it "should always result in a hash of arrays" do
    Dep.all.each {|dep|
      dep.definer.payload[:requires].should be_a Hash
      dep.definer.payload[:requires].each_pair {|k,v|
        k.should be_a Symbol
        v.should be_a Array
      }
    }
  end

  it "should always present an array" do
    Dep.all.each {|dep|
      dep.definer.requires.should be_a Array
    }
  end

  it "should always present the same data" do
    Dep.all.each {|dep|
      values = @deps_to_make[dep.name].is_a?(Hash) ? @deps_to_make[dep.name].values.first : @deps_to_make[dep.name]
      dep.definer.requires.should == [*values]
    }
  end

  after {
    Dep.clear!
  }
end
