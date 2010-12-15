require 'spec_helper'
require 'dep_definer_support'

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
