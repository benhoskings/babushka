require 'spec_support'
require 'dep_support'

describe "Dep.make" do
  it "should reject deps with nonprintable characters in their names" do
    L{
      Dep.make "carriage\rreturn", Base.sources.default, {}, nil, BaseDepDefiner, BaseDepRunner
    }.should raise_error DepError, "The dep name 'carriage\rreturn' contains nonprintable characters."
    dep("carriage\rreturn").should be_nil
  end
  it "should reject deps slashes in their names" do
    L{
      Dep.make "slashes/invalidate names", Base.sources.default, {}, nil, BaseDepDefiner, BaseDepRunner
    }.should raise_error DepError, "The dep name 'slashes/invalidate names' contains '/', which isn't allowed."
    dep("slashes/invalidate names").should be_nil
  end
  it "should create deps with valid names" do
    L{
      Dep.make("valid dep name", Base.sources.default, {}, nil, BaseDepDefiner, BaseDepRunner).should be_an_instance_of(Dep)
    }.should change(Base.sources.default, :count).by(1)
  end
end

describe "dep creation" do
  it "should work for blank deps" do
    L{
      dep "blank"
    }.should change(Source.default_source, :count).by(1)
    Dep('blank').should be_an_instance_of(Dep)
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
    }.should change(Source.default_source, :count).by(1)
    Dep('standard').should be_an_instance_of(Dep)
  end
  it "should accept deps as dep names" do
    L{
      dep 'parent dep' do
        requires dep('nested dep')
      end
    }.should change(Dep.pool, :count).by(2)
    Dep('parent dep').definer.requires.should == [Dep('nested dep')]
  end
  after { Dep.pool.clear! }
end

describe "calling met? on a single dep" do
  before {
    setup_yield_counts
  }
  it "should run if setup returns nil or false" do
    make_counter_dep(
      :name => 'unmeetable for met', :setup => L{ false }, :met? => L{ false }
    ).met?.should == false
    @yield_counts['unmeetable for met'].should == @yield_counts_met_run
  end
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
  after { Source.default_source.deps.clear! }
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
  after { Source.default_source.deps.clear! }
end
