require 'spec_helper'
require 'dep_support'

shared_examples_for "met? when unmet" do
  describe "met?" do
    it "should met?-check deps that don't have failed subdeps" do
      %w[f].each {|dep_name| should_call_dep_like(:already_met, Dep(dep_name)) }
      Dep('a').met?
    end
    it "should not met?-check deps that have failed subdeps" do
      %w[a b c d e].each {|dep_name| should_call_dep_like(:dep_failed, Dep(dep_name)) }
      Dep('a').met?
    end
    it "shouldn't run the meet-only dep" do
      %w[g].each {|dep_name| should_call_dep_like(:none, Dep(dep_name)) }
      Dep('a').met?
    end
  end
end

describe "met? return value" do
  before {
    dep 'return value a' do
      requires 'return value b'
    end
    dep 'return value b' do
      met? { false }
    end
  }
  it "should return false when subdeps are unmet" do
    Dep('return value a').met?.should be_false
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
    it "should met?-check deps that don't have failed subdeps" do
      %w[a b c d e f].each {|dep_name| should_call_dep_like(:already_met, Dep(dep_name)) }
      Dep('a').met?
    end
    it "shouldn't run the meet-only dep" do
      %w[g].each {|dep_name| should_call_dep_like(:none, Dep(dep_name)) }
      Dep('a').met?
    end
  end
  describe "meet" do
    it "should meet no deps" do
      %w[a b c d e f].each {|dep_name| should_call_dep_like(:already_met, Dep(dep_name)) }
      Dep('a').meet
    end
    it "shouldn't run the meet-only dep" do
      %w[g].each {|dep_name| should_call_dep_like(:none, Dep(dep_name)) }
      Dep('a').meet
    end
  end
  after { Base.sources.anonymous.deps.clear! }
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
    it "should fail on the bootom-most dep" do
      %w[f].each {|dep_name| should_call_dep_like(:failed_meet_run, Dep(dep_name)) }
      Dep('a').meet
    end
    it "should bubble the fail back up" do
      %w[a b c].each {|dep_name| should_call_dep_like(:dep_failed, Dep(dep_name)) }
      Dep('a').meet
    end
    it "shouldn't run any deps after the fail" do
      %w[d e g].each {|dep_name| should_call_dep_like(:none, Dep(dep_name)) }
      Dep('a').meet
    end
  end
  after { Base.sources.anonymous.deps.clear! }
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
    it "should meet each dep exactly once" do
      %w[a b c d e f g].each {|dep_name| should_call_dep_like(:meet_run, Dep(dep_name)) }
      Dep('a').meet
    end
  end
  after { Base.sources.anonymous.deps.clear! }
end

describe "a partially meetable dep tree" do
  before {
    dep('a') { met? { @met }; meet { @met = true }; requires('b', 'c') }
    dep('b') { met? { @met }; meet { @met = true }; requires('c', 'd', 'e') }
    dep('c') { met? { @met }; meet { @met = true }; requires('f'); requires_when_unmet('g') }
    dep('d') { met? { @met }; meet { @met = true }; requires('e', 'f') }
    dep('e') { met? { false };                      requires('f') }
    dep('f') { met? { @met }; meet { @met = true } }
    dep('g') { met? { @met }; meet { @met = true } }
  }
  it_should_behave_like "met? when unmet"
  describe "meet" do
    it "should meet deps until one fails" do
      %w[c f g].each {|dep_name| should_call_dep_like(:meet_run, Dep(dep_name)) }
      Dep('a').meet
    end
    it "should fail on the unmeetable dep" do
      %w[e].each {|dep_name| should_call_dep_like(:failed_meet_run, Dep(dep_name)) }
      Dep('a').meet
    end
    it "should bubble the fail up" do
      %w[a b d].each {|dep_name| should_call_dep_like(:dep_failed, Dep(dep_name)) }
      Dep('a').meet
    end
  end
  after { Base.sources.anonymous.deps.clear! }
end
