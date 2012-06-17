# coding: utf-8
require 'spec_helper'
require 'dep_support'

describe "Dep.new" do
  it "should reject deps with empty names" do
    L{
      Dep.new "", Base.sources.anonymous, [], {}, nil
    }.should raise_error(InvalidDepName, "Deps can't have empty names.")
    Dep("carriage\rreturn").should be_nil
  end
  it "should reject deps with nonprintable characters in their names" do
    L{
      Dep.new "carriage\rreturn", Base.sources.anonymous, [], {}, nil
    }.should raise_error(InvalidDepName, "The dep name 'carriage\rreturn' contains nonprintable characters.")
    Dep("carriage\rreturn").should be_nil
  end
  it "should allow deps with unicode characters in their names" do
    L{
      Dep.new "☕script", Base.sources.anonymous, [], {}, nil
    }.should_not raise_error
    Dep("☕script").should be_an_instance_of(Dep)
  end
  it "should reject deps slashes in their names" do
    L{
      Dep.new "slashes/invalidate names", Base.sources.anonymous, [], {}, nil
    }.should raise_error(InvalidDepName, "The dep name 'slashes/invalidate names' contains '/', which isn't allowed (logs are named after deps, and filenames can't contain '/').")
    Dep("slashes/invalidate names").should be_nil
  end
  it "should reject deps colons in their names" do
    L{
      Dep.new "colons:invalidate names", Base.sources.anonymous, [], {}, nil
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
      @dep.template.should == Dep::BaseTemplate
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

describe Dep, '.find_or_suggest' do
  before {
    @dep = dep 'Dep.find_or_suggest tests'
  }
  it "should find the given dep and yield the block" do
    Dep.find_or_suggest('Dep.find_or_suggest tests') {|dep| dep }.should == @dep
  end
  context "namespaced" do
    before {
      Prompt.stub!(:suggest_value_for).and_return(nil)
      @source = Source.new(nil, :name => 'namespaced')
      Source.stub!(:present).and_return([@source])
      Base.sources.load_context :source => @source do
        @namespaced_dep = dep 'namespaced Dep.find_or_suggest tests'
      end
    }
    it "should not find the dep without a namespace" do
      Dep.find_or_suggest('namespaced Dep.find_or_suggest tests').should be_nil
    end
    it "should not find the dep with an incorrect namespace" do
      Dep.find_or_suggest('incorrect:namespaced Dep.find_or_suggest tests').should be_nil
    end
    it "should find the dep with the correct namespace" do
      Dep.find_or_suggest('namespaced:namespaced Dep.find_or_suggest tests').should == @namespaced_dep
    end
    it "should find the dep with the correct namespace and yield it to the block" do
      Dep.find_or_suggest('namespaced:namespaced Dep.find_or_suggest tests') {|dep| dep }.should == @namespaced_dep
    end
  end
  context "from other deps" do
    before {
      @source = Source.new(nil, :name => 'namespaced')
      Source.stub!(:present).and_return([@source])
      Base.sources.load_context :source => @source do
        @namespaced_dep = dep 'namespaced Dep.find_or_suggest tests' do
          requires 'Dep.find_or_suggest sub-dep'
        end
      end
    }
    context "without namespacing" do
      before {
        @sub_dep = dep 'Dep.find_or_suggest sub-dep'
      }
      it "should find the sub dep" do
        @sub_dep.should_receive :process!
        @namespaced_dep.process
      end
    end
    context "in the same namespace" do
      before {
        Base.sources.load_context :source => @source do
          @sub_dep = dep 'Dep.find_or_suggest sub-dep'
        end
      }
      it "should find the sub dep" do
        @sub_dep.should_receive :process!
        @namespaced_dep.process
      end
    end
    context "in a different namespace" do
      before {
        @source = Source.new(nil, :name => 'namespaced')
        @source2 = Source.new(nil, :name => 'another namespaced')
        Source.stub!(:present).and_return([@source, @source2])
        Base.sources.load_context :source => @source do
          @namespaced_dep = dep 'namespaced Dep.find_or_suggest tests' do
            requires 'Dep.find_or_suggest sub-dep'
          end
        end
        Base.sources.load_context :source => @source2 do
          @sub_dep = dep 'Dep.find_or_suggest sub-dep'
        end
      }
      it "should not find the sub dep" do
        @sub_dep.should_not_receive :process
        @namespaced_dep.process
      end
    end
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
      dep('without template').template.should == Dep::BaseTemplate
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

describe Dep, "defining" do
  before {
    Base.sources.stub!(:current_real_load_source).and_return(Base.sources.anonymous)
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
      Base.sources.stub!(:current_real_load_source).and_return(Base.sources.anonymous)
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
        dep.should_not_receive(:process_deps)
        dep.should_not_receive(:process_self)
      }.met?
    end
    it "should not attempt to run later" do
      dep('lazy defining test with errors') do
        nonexistent_method
      end.tap {|dep|
        dep.met?
        dep.should_not_receive(:process_deps)
        dep.should_not_receive(:process_self)
      }.met?
    end
  end
end

describe Dep, '#basename' do
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

describe Dep, '#cache_key' do
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

describe Dep, "params" do
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

describe Dep, 'lambda lists' do
  before {
    Babushka.host.stub!(:name).and_return(:test_name)
    Babushka.host.stub!(:system).and_return(:test_system)
    Babushka.host.stub!(:pkg_helper_key).and_return(:test_helper)

    Babushka::SystemDefinitions.stub!(:all_names).and_return([:test_name, :other_name])
    Babushka::SystemDefinitions.stub!(:all_systems).and_return([:test_system, :other_system])
    Babushka::PkgHelper.stub!(:all_manager_keys).and_return([:test_helper, :other_helper])
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

describe Dep, '#requirements_for' do
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
  after { Base.sources.anonymous.deps.clear! }
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

describe "calling meet on a single dep" do
  before {
    setup_yield_counts
  }
  it "should fail twice and return false on unmeetable deps" do
    make_counter_dep(
      :name => 'unmeetable', :met? => L{ false }
    ).meet.should == false
    @yield_counts['unmeetable'].should == @yield_counts_meet_run
  end
  it "should fail fast and return nil on explicitly unmeetable deps" do
    make_counter_dep(
      :name => 'explicitly unmeetable', :met? => L{ unmeetable! }
    ).meet.should == nil
    @yield_counts['explicitly unmeetable'].should == @yield_counts_met_run
  end
  it "should fail, run meet, and then succeed on unmet deps" do
    make_counter_dep(
      :name => 'unmet', :met? => L{ @yield_counts['unmet'][:met?] > 1 }
    ).meet.should == true
    @yield_counts['unmet'].should == @yield_counts_meet_run
  end
  it "should fail, not run meet, and fail again on unmet deps where before fails" do
    make_counter_dep(
      :name => 'unmet, #before fails', :met? => L{ false }, :before => L{ false }
    ).meet.should == false
    @yield_counts['unmet, #before fails'].should == @yield_counts_failed_at_before
  end
  it "should fail, not run meet, and fail again on unmet deps where meet raises UnmeetableDep" do
    make_counter_dep(
      :name => 'unmet, #before fails', :met? => L{ false }, :meet => L{ unmeetable! }
    ).meet.should == nil
    @yield_counts['unmet, #before fails'].should == @yield_counts_early_exit_meet_run
  end
  it "should fail, run meet, and then succeed on unmet deps where after fails" do
    make_counter_dep(
      :name => 'unmet, #after fails', :met? => L{ @yield_counts['unmet, #after fails'][:met?] > 1 }, :after => L{ false }
    ).meet.should == true
    @yield_counts['unmet, #after fails'].should == @yield_counts_meet_run
  end
  it "should succeed on already met deps" do
    make_counter_dep(
      :name => 'met', :met? => L{ true }
    ).meet.should == true
    @yield_counts['met'].should == @yield_counts_already_met
  end
  after { Base.sources.anonymous.deps.clear! }
end
