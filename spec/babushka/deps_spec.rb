require 'spec_support'
require 'dep_support'

shared_examples_for "met?" do
  describe "met?" do
    before { Dep('a').met? }
    it "should met?-check each dep exactly once" do
      %w[a b c d e f].each {|i| @yield_counts[i].should == @yield_counts_already_met }
    end
    it "shouldn't run the meet-only dep" do
      @yield_counts['g'].should == @yield_counts_none
    end
  end
end

describe "an already met dep tree" do
  before {
    setup_yield_counts
    make_counter_dep :name => 'a', :requires => %w[b c]
    make_counter_dep :name => 'b', :requires => %w[c d e]
    make_counter_dep :name => 'c', :requires => %w[f]
    make_counter_dep :name => 'd', :requires => %w[e f], :requires_when_unmet => %w[g]
    make_counter_dep :name => 'e', :requires => %w[f]
    make_counter_dep :name => 'f'
    make_counter_dep :name => 'g'
  }
  it_should_behave_like "met?"
  describe "meet" do
    before { Dep('a').meet }
    it "should meet no deps" do
      %w[a b c d e f].each {|i| @yield_counts[i].should == @yield_counts_already_met }
    end
    it "shouldn't run the meet-only dep" do
      @yield_counts['g'].should == @yield_counts_none
    end
  end
  after { Base.sources.anonymous.deps.clear! }
end

describe "an unmeetable dep tree" do
  before {
    setup_yield_counts
    make_counter_dep :name => 'a', :met? => L{ false }, :requires => %w[b c]
    make_counter_dep :name => 'b', :met? => L{ false }, :requires => %w[c d e]
    make_counter_dep :name => 'c', :met? => L{ false }, :requires => %w[f], :requires_when_unmet => %w[g]
    make_counter_dep :name => 'd', :met? => L{ false }, :requires => %w[e f]
    make_counter_dep :name => 'e', :met? => L{ false }, :requires => %w[f]
    make_counter_dep :name => 'f', :met? => L{ false }
    make_counter_dep :name => 'g', :met? => L{ false }
  }
  it_should_behave_like "met?"
  describe "meet" do
    before { Dep('a').meet }
    it "should fail on the bootom-most dep" do
      %w[f].each {|i| @yield_counts[i].should == @yield_counts_failed_meet_run }
    end
    it "should bubble the fail back up" do
      %w[a b c].each {|i| @yield_counts[i].should == @yield_counts_dep_failed }
    end
    it "shouldn't run any deps after the fail" do
      %w[d e g].each {|i| @yield_counts[i].should == @yield_counts_none }
    end
  end
  after { Base.sources.anonymous.deps.clear! }
end

describe "a meetable dep tree" do
  before {
    setup_yield_counts
    make_counter_dep :name => 'a', :requires => %w[b c]  , :met? => L{ !@yield_counts['a'][:met?].zero? }
    make_counter_dep :name => 'b', :requires => %w[c d e], :met? => L{ !@yield_counts['b'][:met?].zero? }
    make_counter_dep :name => 'c', :requires => %w[f]    , :met? => L{ !@yield_counts['c'][:met?].zero? }, :requires_when_unmet => %w[g]
    make_counter_dep :name => 'd', :requires => %w[e f]  , :met? => L{ !@yield_counts['d'][:met?].zero? }
    make_counter_dep :name => 'e', :requires => %w[f]    , :met? => L{ !@yield_counts['e'][:met?].zero? }
    make_counter_dep :name => 'f',                         :met? => L{ !@yield_counts['f'][:met?].zero? }
    make_counter_dep :name => 'g',                         :met? => L{ !@yield_counts['g'][:met?].zero? }
  }
  it_should_behave_like "met?"
  describe "meet" do
    before { Dep('a').meet }
    it "should meet each dep exactly once" do
      Base.sources.anonymous.deps.names.each {|i| @yield_counts[i].should == @yield_counts_meet_run }
    end
  end
  after { Base.sources.anonymous.deps.clear! }
end

describe "a partially meetable dep tree" do
  before {
    setup_yield_counts
    make_counter_dep :name => 'a', :requires => %w[b c]  , :met? => L{ !@yield_counts['a'][:met?].zero? }
    make_counter_dep :name => 'b', :requires => %w[c d e], :met? => L{ !@yield_counts['b'][:met?].zero? }
    make_counter_dep :name => 'c', :requires => %w[f]    , :met? => L{ !@yield_counts['c'][:met?].zero? }, :requires_when_unmet => %w[g]
    make_counter_dep :name => 'd', :requires => %w[e f]  , :met? => L{ !@yield_counts['d'][:met?].zero? }
    make_counter_dep :name => 'e', :requires => %w[f]    , :met? => L{ false }
    make_counter_dep :name => 'f',                         :met? => L{ !@yield_counts['f'][:met?].zero? }
    make_counter_dep :name => 'g',                         :met? => L{ !@yield_counts['g'][:met?].zero? }
  }
  it_should_behave_like "met?"
  describe "meet" do
    before { Dep('a').meet }
    it "should meet deps until one fails" do
      %w[c f g].each {|i| @yield_counts[i].should == @yield_counts_meet_run }
    end
    it "should fail on the unmeetable dep" do
      %w[e].each {|i| @yield_counts[i].should == @yield_counts_failed_meet_run }
    end
    it "should bubble the fail up" do
      %w[a b d].each {|i| @yield_counts[i].should == @yield_counts_dep_failed }
    end
  end
  after { Base.sources.anonymous.deps.clear! }
end
