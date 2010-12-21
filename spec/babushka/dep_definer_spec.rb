require 'spec_helper'
require 'dep_definer_support'

describe "source_template" do
  it "should return BaseTemplate" do
    TestDepContext.source_template.should == Dep::BaseTemplate
  end
end

describe "methods in deps" do
  before {
    dep 'helper test' do
      def helper_test
        'hello from the helper method!'
      end
    end
    dep 'another test'
  }
  it "should only be defined on the specified dep" do
    Dep('helper test').context.should respond_to(:helper_test)
    Dep('another test').context.should_not respond_to(:helper_test)
  end
  it "should return the right value" do
    Dep('helper test').context.helper_test.should == 'hello from the helper method!'
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
