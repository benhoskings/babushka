require 'spec_helper'

describe Babushka::Task do
  let(:parser) { Babushka::Cmdline::Parser.for(%w[test]) }

  describe "process" do
    describe "with a dep name" do
      before {
        dep 'task spec'
        expect(Dep('task spec')).to receive(:process)
      }
      it "should run a dep when just the name is passed" do
        Babushka::Base.task.process ['task spec'], {}, parser
      end
    end
    describe "argument assignment" do
      it "should work when with_args contains no arguments" do
        the_dep = dep('task spec arg passing, no args')
        expect(the_dep).to receive(:with).with({}).and_return(the_dep)
        expect(the_dep).to receive(:process)
        Babushka::Base.task.process ['task spec arg passing, no args'], {}, parser
      end
      it "should provide the values in with_args as dep arguments with symbol names" do
        the_dep = dep('task spec arg passing, 1 arg', :arg)
        expect(the_dep).to receive(:with).with({:arg => 'something argy'}).and_return(the_dep)
        expect(the_dep).to receive(:process)
        Babushka::Base.task.process ['task spec arg passing, 1 arg'], {'arg' => 'something argy'}, parser
      end
      it "should print a warning about unexpected arguments, and not pass them to Dep#with" do
        the_dep = dep('task spec arg passing, unexpected arg', :expected)
        expect(Babushka::Base.task).to receive(:log_warn).with(%{Ignoring unexpected argument "unexpected", which the dep 'task spec arg passing, unexpected arg' would reject.})
        expect(the_dep).to receive(:with).with({:expected => 'something argy'}).and_return(the_dep)
        expect(the_dep).to receive(:process)
        Babushka::Base.task.process ['task spec arg passing, unexpected arg'], {'expected' => 'something argy', 'unexpected' => 'nobody expects the Spanish arg!'}, parser
      end
    end
  end

end
