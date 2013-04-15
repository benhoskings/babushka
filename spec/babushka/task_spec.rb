require 'spec_helper'

describe Task do
  let(:parser) { Cmdline::Parser.for(%w[test]) }

  describe "process" do
    describe "with a dep name" do
      before {
        dep 'task spec'
        Dep('task spec').should_receive(:process)
      }
      it "should run a dep when just the name is passed" do
        Base.task.process ['task spec'], {}, parser
      end
    end
    describe "argument assignment" do
      it "should work when with_args contains no arguments" do
        the_dep = dep('task spec arg passing, no args')
        the_dep.should_receive(:with).with({}).and_return(the_dep)
        the_dep.should_receive(:process)
        Base.task.process ['task spec arg passing, no args'], {}, parser
      end
      it "should provide the values in with_args as dep arguments with symbol names" do
        the_dep = dep('task spec arg passing, 1 arg', :arg)
        the_dep.should_receive(:with).with({:arg => 'something argy'}).and_return(the_dep)
        the_dep.should_receive(:process)
        Base.task.process ['task spec arg passing, 1 arg'], {'arg' => 'something argy'}, parser
      end
      it "should print a warning about unexpected arguments, and not pass them to Dep#with" do
        the_dep = dep('task spec arg passing, unexpected arg', :expected)
        Base.task.should_receive(:log_warn).with(%{Ignoring unexpected argument "unexpected", which the dep 'task spec arg passing, unexpected arg' would reject.})
        the_dep.should_receive(:with).with({:expected => 'something argy'}).and_return(the_dep)
        the_dep.should_receive(:process)
        Base.task.process ['task spec arg passing, unexpected arg'], {'expected' => 'something argy', 'unexpected' => 'nobody expects the Spanish arg!'}, parser
      end
    end
  end

  describe 'caching' do
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

end
