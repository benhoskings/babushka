require 'spec_helper'
require 'dep_support'

shared_examples_for "met? when unmet" do
  describe "met?" do
    it "should be false" do
      Dep('a').should_not be_met
    end
    it "should met?-check deps that don't have failed subdeps" do
      %w[f].each {|dep_name| should_call_dep_like(:met_run, Dep(dep_name)) }
      Dep('a').met?
    end
    it "should only setup deps that have failed subdeps" do
      %w[a b c d e].each {|dep_name| should_call_dep_like(:unmet_requirement, Dep(dep_name)) }
      Dep('a').met?
    end
    it "should not touch requires_when_unmet" do
      %w[g].each {|dep_name| should_call_dep_like(:none, Dep(dep_name)) }
      Dep('a').met?
    end
  end
end

describe "an already met dep tree" do
  before {
    dep('a') { requires('b', 'c') }
    dep('b') { requires('c', 'd', 'e') }
    dep('c') { requires('f'); requires_when_unmet('g') }
    dep('d') { requires('e', 'f') }
    dep('e') { requires('f') }
    dep('f')
    dep('g')
  }
  describe "met?" do
    it "should be true" do
      Dep('a').should be_met
    end
    it "should met?-check every dep" do
      %w[a b c d e f].each {|dep_name| should_call_dep_like(:met_run, Dep(dep_name)) }
      Dep('a').met?
    end
    it "should not touch requires_when_unmet" do
      %w[g].each {|dep_name| should_call_dep_like(:none, Dep(dep_name)) }
      Dep('a').met?
    end
  end
  describe "meet" do
    it "should be true" do
      Dep('a').meet.should == true
    end
    it "should not meet any deps" do
      %w[a b c d e f].each {|dep_name| should_call_dep_like(:met_run, Dep(dep_name)) }
      Dep('a').meet
    end
    it "should not touch requires_when_unmet" do
      %w[g].each {|dep_name| should_call_dep_like(:none, Dep(dep_name)) }
      Dep('a').meet
    end
  end
  after { Babushka::Base.sources.anonymous.deps.clear! }
end

describe "an unmeetable dep tree" do
  before {
    dep('a') { met? { false }; requires('b', 'c') }
    dep('b') { met? { false }; requires('c', 'd', 'e') }
    dep('c') { met? { false }; requires('f'); requires_when_unmet('g') }
    dep('d') { met? { false }; requires('e', 'f') }
    dep('e') { met? { false }; requires('f') }
    dep('f') { met? { false } }
    dep('g') { met? { false } }
  }
  it_should_behave_like "met? when unmet"
  describe "meet" do
    it "should be false" do
      Dep('a').meet.should == false
    end
    it "should fail on the bootom-most dep" do
      %w[f].each {|dep_name| should_call_dep_like(:meet_run, Dep(dep_name)) }
      Dep('a').meet
    end
    it "should bubble the failure back up from the failed dep" do
      %w[a b c].each {|dep_name| should_call_dep_like(:unmet_requirement, Dep(dep_name)) }
      Dep('a').meet
    end
    it "shouldn't run any subdeps after the point of failure" do
      %w[d e g].each {|dep_name| should_call_dep_like(:none, Dep(dep_name)) }
      Dep('a').meet
    end
  end
  after { Babushka::Base.sources.anonymous.deps.clear! }
end

describe "a meetable dep tree" do
  before {
    dep('a') { met? { @met }; meet { @met = true }; requires('b', 'c') }
    dep('b') { met? { @met }; meet { @met = true }; requires('c', 'd', 'e') }
    dep('c') { met? { @met }; meet { @met = true }; requires('f'); requires_when_unmet('g') }
    dep('d') { met? { @met }; meet { @met = true }; requires('e', 'f') }
    dep('e') { met? { @met }; meet { @met = true }; requires('f') }
    dep('f') { met? { @met }; meet { @met = true } }
    dep('g') { met? { @met }; meet { @met = true } }
  }
  it_should_behave_like "met? when unmet"
  describe "meet" do
    it "should be true" do
      Dep('a').meet.should == true
    end
    it "should meet every dep" do
      %w[a b c d e f g].each {|dep_name| should_call_dep_like(:meet_run, Dep(dep_name)) }
      Dep('a').meet
    end
  end
  after { Babushka::Base.sources.anonymous.deps.clear! }
end

describe "a partially meetable dep tree" do
  before {
    dep('a') { met? { @met }; meet { @met = true }; requires('b', 'c') }
    dep('b') { met? { @met }; meet { @met = true }; requires('c', 'd', 'e') }
    dep('c') { met? { @met }; meet { @met = true }; requires('f'); requires_when_unmet('g') }
    dep('d') { met? { false };                      requires('f') }
    dep('e') { met? { @met }; meet { @met = true }; requires('f') }
    dep('f') { met? { @met }; meet { @met = true } }
    dep('g') { met? { @met }; meet { @met = true } }
  }
  it_should_behave_like "met? when unmet"
  describe "meet" do
    it "should be false" do
      Dep('a').meet.should == false
    end
    it "should meet deps before the unmeetable dep is reached" do
      %w[c f g].each {|dep_name| should_call_dep_like(:meet_run, Dep(dep_name)) }
      Dep('a').meet
    end
    it "should attempt to meet the unmeetable dep" do
      %w[d].each {|dep_name| should_call_dep_like(:meet_run, Dep(dep_name)) }
      Dep('a').meet
    end
    it "should bubble the failure back up from the unmeetable dep" do
      %w[a b].each {|dep_name| should_call_dep_like(:unmet_requirement, Dep(dep_name)) }
      Dep('a').meet
    end
    it "shouldn't run any subdeps after the point of failure" do
      %w[e].each {|dep_name| should_call_dep_like(:none, Dep(dep_name)) }
      Dep('a').meet
    end
  end
  after { Babushka::Base.sources.anonymous.deps.clear! }
end
