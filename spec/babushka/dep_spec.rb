# coding: utf-8

require 'spec_helper'
require 'dep_support'

describe "Dep.new" do
  it "should reject deps with non-string names" do
    L{
      Dep.new(:symbol_name, Base.sources.anonymous, [], {}, nil)
    }.should raise_error(InvalidDepName, "The dep name :symbol_name isn't a string.")
  end
  it "should reject deps with empty names" do
    L{
      Dep.new("", Base.sources.anonymous, [], {}, nil)
    }.should raise_error(InvalidDepName, "Deps can't have empty names.")
    Dep("carriage\rreturn").should be_nil
  end
  it "should reject deps with nonprintable characters in their names" do
    L{
      Dep.new("carriage\rreturn", Base.sources.anonymous, [], {}, nil)
    }.should raise_error(InvalidDepName, "The dep name 'carriage\rreturn' contains nonprintable characters.")
    Dep("carriage\rreturn").should be_nil
  end
  it "should allow deps with unicode characters in their names" do
    L{
      Dep.new("☕script", Base.sources.anonymous, [], {}, nil)
    }.should_not raise_error
    Dep("☕script").should be_an_instance_of(Dep)
  end
  it "should reject deps slashes in their names" do
    L{
      Dep.new("slashes/invalidate names", Base.sources.anonymous, [], {}, nil)
    }.should raise_error(InvalidDepName, "The dep name 'slashes/invalidate names' contains '/', which isn't allowed (logs are named after deps, and filenames can't contain '/').")
    Dep("slashes/invalidate names").should be_nil
  end
  it "should reject deps colons in their names" do
    GitHelpers.stub(:git) # To avoid cloning.
    L{
      Dep.new("colons:invalidate names", Base.sources.anonymous, [], {}, nil)
    }.should raise_error(InvalidDepName, "The dep name 'colons:invalidate names' contains ':', which isn't allowed (colons separate dep and template names from source prefixes).")
    Dep("colons:invalidate names").should be_nil
  end
  it "should create deps with valid names" do
    L{
      Dep.new("valid dep name", Base.sources.anonymous, [], {}, nil)
    }.should change(Base.sources.anonymous.deps, :count).by(1)
    Dep("valid dep name").should be_an_instance_of(Dep)
  end
  it "should store the params" do
    L{
      Dep.new("valid dep with params", Base.sources.anonymous, [:some, :params], {}, nil)
    }.should change(Base.sources.anonymous.deps, :count).by(1)
    Dep("valid dep with params").params.should == [:some, :params]
  end
  context "without template" do
    before {
      @dep = Dep.new("valid base dep", Base.sources.anonymous, [], {}, nil)
    }
    it "should work" do
      @dep.should be_an_instance_of(Dep)
      @dep.template.should == Dep.base_template
    end
  end
  context "with a missing template" do
    it "should fail to define optioned deps against a missing template" do
      L{
        Dep.new("valid but missing template", Base.sources.anonymous, [], {:template => 'template'}, nil).template
      }.should raise_error(TemplateNotFound, "There is no template named 'template' to define 'valid but missing template' against.")
    end
  end
  context "with template" do
    before {
      @meta = meta('template')
    }
    it "should work when passed as an option" do
      Dep.new("valid option dep", Base.sources.anonymous, [], {:template => 'template'}, nil).tap {|dep|
        dep.should be_an_instance_of(Dep)
        dep.template.should == @meta
      }
    end
    it "should work when passed as a suffix" do
      Dep.new("valid dep name.template", Base.sources.anonymous, [], {}, nil).tap {|dep|
        dep.should be_an_instance_of(Dep)
        dep.template.should == @meta
      }
    end
    after { Base.sources.anonymous.templates.clear! }
  end
end

describe '#inspect' do
  let(:source) {
    Source.new(nil, 'test source')
  }
  it "should represent the dep and its source" do
    the_dep = Dep.new('inspect test', source, [], {}, nil)
    the_dep.inspect.should == "#<Dep:#{the_dep.object_id} 'test source:inspect test'>"
  end
end

describe "dep creation" do
  it "should work for blank deps" do
    L{
      dep "a blank dep"
    }.should change(Base.sources.anonymous.deps, :count).by(1)
    Dep('a blank dep').should be_an_instance_of(Dep)
  end
  it "should work for filled in deps" do
    L{
      dep "a standard dep" do
        requires 'some other dep'
        before { }
        met? { }
        meet { }
        after { }
      end
    }.should change(Base.sources.anonymous.deps, :count).by(1)
    Dep('a standard dep').should be_an_instance_of(Dep)
  end
  it "should accept deps as dep names" do
    L{
      dep 'parent dep' do
        requires dep('nested dep')
      end.met?
    }.should change(Base.sources.anonymous.deps, :count).by(2)
    Dep('parent dep').context.requires.should == [Dep('nested dep')]
  end
  after { Base.sources.anonymous.deps.clear! }

  context "without template" do
    it "should use the base template" do
      dep('without template').template.should == Dep.base_template
    end
  end
  context "with template" do
    before {
      @template = meta 'template'
    }
    it "should use the template when passed as an option" do
      dep('with template', :template => 'template').tap {|dep|
        dep.template.should == @template
        dep.should_not be_suffixed
        dep.suffix.should be_nil
      }
    end
    it "should use the template and be suffixed when passed as a suffix" do
      dep('with template.template').tap {|dep|
        dep.template.should == @template
        dep.should be_suffixed
        dep.suffix.should == 'template'
      }
    end
    context "when both are passed" do
      before {
        @another_template = meta 'another_template'
      }
      it "should use the option template" do
        dep('with both templates.template', :template => 'another_template').tap {|dep|
          dep.template.should == @another_template
          dep.should_not be_suffixed
          dep.suffix.should == 'template'
        }
      end
    end
  end
  after { Base.sources.anonymous.templates.clear! }
end

describe Babushka::Dep, "defining" do
  before {
    Base.sources.stub(:current_real_load_source).and_return(Base.sources.anonymous)
  }
  it "should not define the dep when called without a block" do
    dep('lazy defining test').context.should_not be_loaded
  end
  it "should not define the dep when called with a block" do
    dep('lazy defining test with block') do
      requires 'another dep'
    end.context.should_not be_loaded
  end
  context "after running" do
    it "should be defined" do
      dep('lazy defining test with run').tap {|dep|
        dep.met?
      }.context.should be_loaded
    end
    context "with a template" do
      let!(:template) { meta 'lazy_defining_template' }
      it "should use the template" do
        dep('lazy defining test with template.lazy_defining_template').tap {|dep|
          dep.met?
        }.template.should == template
      end
    end
  end
  context "with params" do
    it "should run against subsequent parameters" do
      parameter = Parameter.new(:arg)
      dep('parameter preserving', :arg) {
        arg.default!('a default value')
      }.tap {|dep|
        dep.met?('some other value')
        dep.met?(parameter)
      }
      parameter.description.should == 'arg: [default!: "a default value"]'
    end
  end
  context "with errors" do
    before {
      Base.sources.stub(:current_real_load_source).and_return(Base.sources.anonymous)
    }
    it "should not be defined, and then have failed defining after a run" do
      dep('lazy defining test with errors') do
        nonexistent_method
      end.tap {|dep|
        dep.context.should_not be_loaded
        dep.met?
      }.context.should be_failed
    end
    it "should not attempt to run" do
      dep('lazy defining test with errors') do
        nonexistent_method
      end.tap {|dep|
        dep.should_not_receive(:run_requirements)
        dep.should_not_receive(:run_met)
      }.met?
    end
    it "should not attempt to run later" do
      dep('lazy defining test with errors') do
        nonexistent_method
      end.tap {|dep|
        dep.met?
        dep.should_not_receive(:run_requirements)
        dep.should_not_receive(:run_met)
      }.met?
    end
  end
end

describe Babushka::Dep, '#basename' do
  context "for base deps" do
    it "should be the same as the dep's name" do
      dep('basename test').basename.should == 'basename test'
    end
    context "with a suffix" do
      it "should be the same as the dep's name" do
        dep('basename test.basename_test').basename.should == 'basename test.basename_test'
      end
    end
  end
  context "for option-templated deps" do
    before { meta 'basename_template' }
    it "should be the same as the dep's name" do
      dep('basename test', :template => 'basename_template').basename.should == 'basename test'
    end
    context "with a suffix" do
      it "should be the same as the dep's name" do
        dep('basename test.basename_template', :template => 'basename_template').basename.should == 'basename test.basename_template'
      end
    end
    after {
      Base.sources.anonymous.deps.clear!
      Base.sources.anonymous.templates.clear!
    }
  end
  context "for suffix-templated deps" do
    before { meta 'basename_template' }
    it "should remove the suffix name" do
      dep('basename test.basename_template').basename.should == 'basename test'
    end
    after {
      Base.sources.anonymous.deps.clear!
      Base.sources.anonymous.templates.clear!
    }
  end
end

describe Babushka::Dep, '#cache_key' do
  it "should work for parameterless deps" do
    dep('cache key, no params').cache_key.should == DepRequirement.new('cache key, no params', [])
  end
  it "should work for parameterised deps with no args" do
    dep('cache key, no args', :arg1, :arg2).cache_key.should == DepRequirement.new('cache key, no args', [nil, nil])
  end
  it "should work for parameterised deps with named args" do
    dep('cache key, named args', :arg1, :arg2).with(:arg2 => 'value').cache_key.should == DepRequirement.new('cache key, named args', [nil, 'value'])
  end
  it "should work for parameterised deps positional args" do
    dep('cache key, positional args', :arg1, :arg2).with('value', 'another').cache_key.should == DepRequirement.new('cache key, positional args', ['value', 'another'])
  end
end

describe Babushka::Dep, "params" do
  describe "non-symbol params" do
    it "should be rejected, singular" do
      L{
        dep('non-symbol param', 'a')
      }.should raise_error(DepParameterError, %{The dep 'non-symbol param' has a non-symbol param "a", which isn't allowed.})
    end
    it "should be rejected, plural" do
      L{
        dep('non-symbol params', 'a', 'b')
      }.should raise_error(DepParameterError, %{The dep 'non-symbol params' has non-symbol params "a" and "b", which aren't allowed.})
    end
  end
  it "should define methods on the context" do
    dep('params test', :a_param).context.define!.should respond_to(:a_param)
  end
  it "should raise on conflicting methods" do
    L{
      dep('conflicting param names', :name).context.define!
    }.should raise_error(DepParameterError, "You can't use :name as a parameter (on 'conflicting param names'), because that's already a method on Babushka::DepDefiner.")
  end
  it "should discard the context" do
    dep('context discarding').tap {|dep|
      dep.context.should_not == dep.with.context
    }
  end
  it "should not pollute other deps" do
    dep('params test', :a_param)
    Dep('params test').context.define!.should respond_to(:a_param)
    dep('paramless dep').context.define!.should_not respond_to(:a_param)
  end
  it "should return a param containing the value when it's set" do
    dep('set params test', :a_set_param)
    Dep('set params test').with('a value').context.define!.a_set_param.should be_an_instance_of(Parameter)
    Dep('set params test').with('a value').context.define!.a_set_param.to_s.should == 'a value'
  end
  it "should ask for the value when it's not set" do
    dep('unset params test', :an_unset_param).context.define!
    Dep('unset params test').context.an_unset_param.should be_an_instance_of(Parameter)
    Prompt.should_receive(:get_value).with('an_unset_param', {}).and_return('a value from the prompt')
    Dep('unset params test').context.an_unset_param.to_s.should == 'a value from the prompt'
  end
end

describe Babushka::Dep, 'lambda lists' do
  before {
    Babushka.host.matcher.stub(:name).and_return(:test_name)
    Babushka.host.matcher.stub(:system).and_return(:test_system)
    Babushka.host.matcher.stub(:pkg_helper_key).and_return(:test_helper)

    Babushka::SystemDefinition.stub(:all_names).and_return([:test_name, :other_name])
    Babushka::SystemDefinition.stub(:all_systems).and_return([:test_system, :other_system])
    Babushka::PkgHelper.stub(:all_manager_keys).and_return([:test_helper, :other_helper])
  }
  it "should match against the system name" do
    dep('lambda list name match') { requires { on :test_name, 'awesome' } }.context.define!.requires.should == ['awesome']
  end
  it "should match against the system type" do
    dep('lambda list system match') { requires { on :test_system, 'awesome' } }.context.define!.requires.should == ['awesome']
  end
  it "should match against the system name" do
    dep('lambda list pkg_helper_key match') { requires { on :test_helper, 'awesome' } }.context.define!.requires.should == ['awesome']
  end
end

describe Babushka::Dep, '#requirements_for' do
  let(:dependency) {
    dep('requirements_for specs') {
      requires 'a dep'
      requires 'another dep'.with(:some, :args)
      requires 'a third'.with()
    }.tap {|d|
      d.context.define!
    }
  }
  let(:requirements) {
    dependency.send(:requirements_for, :requires)
  }
  it "should have the right number of requirements" do
    requirements.length.should == 3
  end
  it "should return a DepRequirement for all the required deps" do
    requirements.each {|c| c.should be_an_instance_of(Babushka::DepRequirement) }
  end
  it "should contain the right dep names" do
    requirements.map(&:name).should == ['a dep', 'another dep', 'a third']
  end
  it "should work with empty args" do
    requirements[0].args.should == []
    requirements[2].args.should == []
  end
  context "arguments" do
    let(:args) { requirements[1].args }
    it "should have the right number of args" do
      args.length.should == 2
    end
    it "should contain the right args" do
      args.should == [:some, :args]
    end
  end
end

describe "exceptions" do
  it "should be unmet after an exception in met? {}" do
    dep 'exception met? test' do
      met? { raise }
    end.met?.should be_false
  end
  it "should be unmet after an exception in meet {}" do
    dep 'exception meet test' do
      met? { false }
      meet { raise }
    end.met?.should be_false
  end
end

describe "calling met? on a single dep" do
  it "should still call met? if setup returns falsey" do
    the_dep = dep('met? - setup is false') {
      setup { false }
    }
    should_call_dep_like(:met_run, the_dep)
    the_dep.should be_met
  end
  it "should be false for unmet deps" do
    the_dep = dep('met? - unmet') {
      met? { false }
    }
    should_call_dep_like(:met_run, the_dep)
    the_dep.should_not be_met
  end
  it "should be true for met deps" do
    the_dep = dep('met? - met') {
      met? { true }
    }
    should_call_dep_like(:met_run, the_dep)
    the_dep.should be_met
  end
  after { Base.sources.anonymous.deps.clear! }
end

describe "calling meet on a single dep" do
  it "should be false for an unmeetable dep" do
    the_dep = dep('unmeetable') {
      met? { false }
    }
    should_call_dep_like(:meet_run, the_dep)
    the_dep.meet.should == false
  end
  it "should be nil for an explicitly unmeetable dep" do
    the_dep = dep('explicitly unmeetable') {
      met? { unmeetable! }
    }
    should_call_dep_like(:met_run, the_dep)
    the_dep.meet.should == nil
  end
  it "should be true for a meetable dep" do
    the_dep = dep('unmet') {
      met? { @met }
      meet { @met = true }
    }
    should_call_dep_like(:meet_run, the_dep)
    the_dep.meet.should == true
  end
  it "should be false for an unmet dep when before is false" do
    the_dep = dep('unmet, #before is false') {
      met? { false }
      before { false }
    }
    should_call_dep_like(:meet_skipped, the_dep)
    the_dep.meet.should == false
  end
  it "should be false for an unmet dep when meet fails" do
    the_dep = dep('unmet, #meet fails') {
      met? { false }
      meet { unmeetable! }
    }
    should_call_dep_like(:meet_failed, the_dep)
    the_dep.meet.should == nil
  end
  it "should be true for an unmet dep when after fails" do
    the_dep = dep('unmet, #after fails') {
      met? { @met }
      meet { @met = true }
      after { false }
    }
    should_call_dep_like(:meet_run, the_dep)
    the_dep.meet.should == true
  end
  it "should be true for an already met dep" do
    the_dep = dep('met') {
      met? { true }
    }
    should_call_dep_like(:met_run, the_dep)
    the_dep.meet.should == true
  end
  after { Base.sources.anonymous.deps.clear! }
end

describe 'dep caching' do
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
    Dep('caching parent').should_receive(:run_met).once
    Dep('caching child a').should_receive(:run_met).once.and_return(true)
    Dep('caching child b').should_receive(:run_met).twice.and_return(true)
    Dep('caching child c').should_receive(:run_met).once.and_return(true)

    Dep('caching parent').met?
  end
end

describe "fs snapshotting" do
  before {
    Base.task.stub(:opt).and_return(false)
    Base.task.stub(:opt).with(:git_fs).and_return(true)
  }
  context "when the dep is already met" do
    let(:the_dep) {
      dep('snapshotting - met')
    }
    it "should not snapshot" do
      Babushka::GitFS.should_not_receive(:commit)
      the_dep.meet
    end
  end
  context "when the dep can't be met" do
    let(:the_dep) {
      dep('snapshotting - unmeetable') {
        met? { false }
      }
    }
    it "should not snapshot" do
      Babushka::GitFS.should_not_receive(:commit)
      the_dep.meet
    end
  end
  context "when the dep can be met" do
    let(:the_dep) {
      dep('snapshotting - unmet') {
        met? { @run }
        meet { @run = true }
      }
    }
    it "should snapshot after meeting the dep" do
      Babushka::GitFS.should_receive(:init)
      the_dep.should_receive(:run_meet_stage).and_call_original
      Babushka::GitFS.should_receive(:commit).with("babushka 'snapshotting - unmet'\n\n")
      the_dep.meet
    end
    context "when snapshotting is disabled" do
      before {
        Base.task.stub(:opt).and_return(false)
        Base.task.stub(:opt).with(:git_fs).and_return(false)
      }
      it "should not snapshot" do
        Babushka::GitFS.should_not_receive(:commit)
        the_dep.meet
      end
    end
  end
end
