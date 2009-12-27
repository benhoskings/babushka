require 'spec_support'
require 'dep_support'

describe "an already met dep tree" do
  before {
    setup_yield_counts
    make_counter_dep :name => 'a', :requires => %w[b c]
    make_counter_dep :name => 'b', :requires => %w[c d e]
    make_counter_dep :name => 'c', :requires => %w[f]
    make_counter_dep :name => 'd', :requires => %w[e f]
    make_counter_dep :name => 'e', :requires => %w[f]
    make_counter_dep :name => 'f'
  }
  it "should met?-check each dep exactly once" do
    Dep('a').met?
    Dep.pool.names.each {|i| @yield_counts[i].should == @yield_counts_already_met }
  end
  it "should meet no deps" do
    Dep('a').meet
    Dep.pool.names.each {|i| @yield_counts[i].should == @yield_counts_already_met }
  end
  after { Dep.pool.clear! }
end

describe "an unmeetable dep tree" do
  before {
    setup_yield_counts
    make_counter_dep :name => 'a', :met? => L{ false }, :requires => %w[b c]
    make_counter_dep :name => 'b', :met? => L{ false }, :requires => %w[c d e]
    make_counter_dep :name => 'c', :met? => L{ false }, :requires => %w[f]
    make_counter_dep :name => 'd', :met? => L{ false }, :requires => %w[e f]
    make_counter_dep :name => 'e', :met? => L{ false }, :requires => %w[f]
    make_counter_dep :name => 'f', :met? => L{ false }
  }
  it "should met?-check each dep exactly once" do
    Dep('a').met?
    Dep.pool.names.each {|i| @yield_counts[i].should == @yield_counts_met_run }
  end
  it "should meet each dep exactly once" do
    Dep('a').meet
    @yield_counts['f'].should == @yield_counts_failed_meet_run
    %w[a b c].each {|i| @yield_counts[i].should == @yield_counts_dep_failed }
    %w[d e].each {|i| @yield_counts[i].should == @yield_counts_none }
  end
  after { Dep.pool.clear! }
end

describe "a meetable dep tree" do
  before {
    setup_yield_counts
    make_counter_dep :name => 'a', :requires => %w[b c]  , :met? => L{ !@yield_counts['a'][:met?].zero? }
    make_counter_dep :name => 'b', :requires => %w[c d e], :met? => L{ !@yield_counts['b'][:met?].zero? }
    make_counter_dep :name => 'c', :requires => %w[f]    , :met? => L{ !@yield_counts['c'][:met?].zero? }
    make_counter_dep :name => 'd', :requires => %w[e f]  , :met? => L{ !@yield_counts['d'][:met?].zero? }
    make_counter_dep :name => 'e', :requires => %w[f]    , :met? => L{ !@yield_counts['e'][:met?].zero? }
    make_counter_dep :name => 'f',                         :met? => L{ !@yield_counts['f'][:met?].zero? }
  }
  it "should met?-check each dep exactly once" do
    Dep('a').met?
    Dep.pool.names.each {|i| @yield_counts[i].should == @yield_counts_met_run }
  end
  it "should meet each dep exactly once" do
    Dep('a').meet
    Dep.pool.names.each {|i| @yield_counts[i].should == @yield_counts_meet_run }
  end
  after { Dep.pool.clear! }
end

describe "a partially meetable dep tree" do
  before {
    setup_yield_counts
    make_counter_dep :name => 'a', :requires => %w[b c]  , :met? => L{ !@yield_counts['a'][:met?].zero? }
    make_counter_dep :name => 'b', :requires => %w[c d e], :met? => L{ !@yield_counts['b'][:met?].zero? }
    make_counter_dep :name => 'c', :requires => %w[f]    , :met? => L{ !@yield_counts['c'][:met?].zero? }
    make_counter_dep :name => 'd', :requires => %w[e f]  , :met? => L{ !@yield_counts['d'][:met?].zero? }
    make_counter_dep :name => 'e', :requires => %w[f]    , :met? => L{ false }
    make_counter_dep :name => 'f',                         :met? => L{ !@yield_counts['f'][:met?].zero? }
  }
  it "should met?-check each dep exactly once" do
    Dep('a').met?
    Dep.pool.names.each {|i| @yield_counts[i].should == @yield_counts_met_run }
  end
  it "should meet each dep exactly once" do
    Dep('a').meet
    %w[c f].each {|i| @yield_counts[i].should == @yield_counts_meet_run }
    %w[e].each {|i| @yield_counts[i].should == @yield_counts_failed_meet_run }
    %w[a b d].each {|i| @yield_counts[i].should == @yield_counts_dep_failed }
  end
  after { Dep.pool.clear! }
end
