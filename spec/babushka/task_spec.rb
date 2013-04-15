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

end
