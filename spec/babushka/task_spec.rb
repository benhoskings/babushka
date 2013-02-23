require 'spec_helper'
require 'source_support'


describe Task, "process" do
  describe "with a dep name" do
    before {
      dep 'task spec'
      Dep('task spec').should_receive(:process)
    }
    it "should run a dep when just the name is passed" do
      Base.task.process ['task spec'], {}
    end
  end
  describe "argument assignment" do
    it "should work when with_args contains no arguments" do
      the_dep = dep('task spec arg passing, no args')
      the_dep.should_receive(:with).with({}).and_return(the_dep)
      the_dep.should_receive(:process)
      Base.task.process ['task spec arg passing, no args'], {}
    end
    it "should provide the values in with_args as dep arguments with symbol names" do
      the_dep = dep('task spec arg passing, 1 arg', :arg)
      the_dep.should_receive(:with).with({:arg => 'something argy'}).and_return(the_dep)
      the_dep.should_receive(:process)
      Base.task.process ['task spec arg passing, 1 arg'], {'arg' => 'something argy'}
    end
    it "should print a warning about unexpected arguments, and not pass them to Dep#with" do
      the_dep = dep('task spec arg passing, unexpected arg', :expected)
      Base.task.should_receive(:log_warn).with(%{Ignoring unexpected argument "unexpected", which the dep 'task spec arg passing, unexpected arg' would reject.})
      the_dep.should_receive(:with).with({:expected => 'something argy'}).and_return(the_dep)
      the_dep.should_receive(:process)
      Base.task.process ['task spec arg passing, unexpected arg'], {'expected' => 'something argy', 'unexpected' => 'nobody expects the Spanish arg!'}
    end
  end
end

describe Task, 'caching' do
  it "should not cache outside a #cache block" do
    counter = 0
    Base.task.cached(:not_caching) { counter += 1 }
    Base.task.cached(:not_caching) { counter += 1 }
    counter.should == 2
  end
  it "should not yield #hit on a cache miss" do
    hit = false
    Base.task.cache {
      Base.task.cached(:key_miss, :hit => lambda{ hit = true }) {
        'a miss'
      }.should == 'a miss'
    }
    hit.should be_false
  end
  it "should yield #hit on a cache hit" do
    hit = false
    Base.task.cache {
      Base.task.cached(:key_hit) { 'a hit' }
      Base.task.cached(:key_hit, :hit => lambda{|value| hit = value })
    }
    hit.should == 'a hit'
  end
  it "should maintain the cached value" do
    result = nil
    Base.task.cache {
      Base.task.cached(:key_another_hit) { 'another hit' }
      result = Base.task.cached(:key_another_hit) { 'a replacement' }
    }
    result.should == 'another hit'
  end
end

describe Task, 'dep caching' do
  before {
    dep 'caching child b', :arg_b1, :arg_b2
    dep 'caching child c', :arg_c1
    dep 'caching child a', :arg_a do
      requires 'caching child b'.with(:arg_b2 => 'a value')
      requires 'caching child c'.with('some value')
    end
    dep 'caching parent' do
      requires 'caching child a'
      requires 'caching child b'.with('more', 'values')
      requires 'caching child c'.with('some value')
    end
  }
  it "should run the deps the right number of times" do
    Dep('caching parent').should_receive(:process_self).once
    Dep('caching child a').should_receive(:process_self).once.and_return(true)
    Dep('caching child b').should_receive(:process_self).twice.and_return(true)
    Dep('caching child c').should_receive(:process_self).once.and_return(true)
    Base.task.process ['caching parent'], {}
  end
  it "should cache the dep requirements" do
    Base.task.process ['caching parent'], {}
    Base.task.caches.should == {
      DepRequirement.new('caching parent', []) => true,
      DepRequirement.new('caching child a', [nil]) => true,
      DepRequirement.new('caching child b', [nil, 'a value']) => true,
      DepRequirement.new('caching child b', ['more', 'values']) => true,
      DepRequirement.new('caching child c', ['some value']) => true
    }
  end
end
