require 'spec/spec_support'
require 'spec/dep_support'

describe "dep creation" do
  it "should work for blank deps" do
    L{
      dep "blank"
    }.should change(Dep, :count).by(1)
  end
  it "should work for filled in deps" do
    L{
      dep "standard" do
        requires 'blank'
        before { }
        met? { }
        meet { }
        after { }
      end
    }.should change(Dep, :count).by(1)
  end
  after { Dep.clear! }
end

describe "calling met? on a single dep" do
  before {
    setup_yield_counts
  }
  it "should return false for unmet deps" do
    make_counter_dep(
      :name => 'unmeetable for met', :met? => L{ false }
    ).met?.should == false
    @yield_counts['unmeetable for met'].should == @yield_counts_met_run
  end
  it "should return true for already met deps" do
    make_counter_dep(
      :name => 'met for met'
    ).met?.should == true
    @yield_counts['met for met'].should == @yield_counts_met_run
  end
  after { Dep.clear! }
end

describe "calling meet on a single dep" do
  before {
    setup_yield_counts
  }
  it "should fail twice on unmeetable deps" do
    make_counter_dep(
      :name => 'unmeetable', :met? => L{ false }
    ).meet.should == false
    @yield_counts['unmeetable'].should == @yield_counts_meet_run
  end
  it "should fail, run meet, and then succeed on unmet deps" do
    make_counter_dep(
      :name => 'unmet', :met? => L{ !@yield_counts['unmet'][:met?].zero? }
    ).meet.should == true
    @yield_counts['unmet'].should == @yield_counts_meet_run
  end
  it "should fail, not run meet, and fail again on unmet deps where before fails" do
    make_counter_dep(
      :name => 'unmet, #before fails', :met? => L{ false }, :before => L{ false }
    ).meet.should == false
    @yield_counts['unmet, #before fails'].should == @yield_counts_failed_at_before
  end
  it "should fail, run meet, and then succeed on unmet deps where after fails" do
    make_counter_dep(
      :name => 'unmet, #after fails', :met? => L{ !@yield_counts['unmet, #after fails'][:met?].zero? }, :after => L{ false }
    ).meet.should == true
    @yield_counts['unmet, #after fails'].should == @yield_counts_meet_run
  end
  it "should succeed on already met deps" do
    make_counter_dep(
      :name => 'met', :met? => L{ true }
    ).meet.should == true
    @yield_counts['met'].should == @yield_counts_already_met
  end
  after { Dep.clear! }
end
