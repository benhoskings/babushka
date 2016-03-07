# coding: utf-8

require 'spec_helper'
require 'dep_support'

RSpec.describe "Dep.new" do
  it "should reject deps with non-string names" do
    expect {
      Babushka::Dep.new(:symbol_name, Babushka::Base.sources.anonymous, [], {}, nil)
    }.to raise_error(Babushka::InvalidDepName, "The dep name :symbol_name isn't a string.")
  end
  it "should reject deps with empty names" do
    expect {
      Babushka::Dep.new("", Babushka::Base.sources.anonymous, [], {}, nil)
    }.to raise_error(Babushka::InvalidDepName, "Deps can't have empty names.")
    expect(Dep("carriage\rreturn")).to be_nil
  end
  it "should reject deps with nonprintable characters in their names" do
    expect {
      Babushka::Dep.new("carriage\rreturn", Babushka::Base.sources.anonymous, [], {}, nil)
    }.to raise_error(Babushka::InvalidDepName, "The dep name 'carriage\rreturn' contains nonprintable characters.")
    expect(Dep("carriage\rreturn")).to be_nil
  end
  it "should allow deps with unicode characters in their names" do
    expect {
      Babushka::Dep.new("☕script", Babushka::Base.sources.anonymous, [], {}, nil)
    }.not_to raise_error
    expect(Dep("☕script")).to be_an_instance_of(Babushka::Dep)
  end
  it "should reject deps slashes in their names" do
    expect {
      Babushka::Dep.new("slashes/invalidate names", Babushka::Base.sources.anonymous, [], {}, nil)
    }.to raise_error(Babushka::InvalidDepName, "The dep name 'slashes/invalidate names' contains '/', which isn't allowed (logs are named after deps, and filenames can't contain '/').")
    expect(Dep("slashes/invalidate names")).to be_nil
  end
  it "should reject deps colons in their names" do
    allow(Babushka::GitHelpers).to receive(:git) # To avoid cloning.
    expect {
      Babushka::Dep.new("colons:invalidate names", Babushka::Base.sources.anonymous, [], {}, nil)
    }.to raise_error(Babushka::InvalidDepName, "The dep name 'colons:invalidate names' contains ':', which isn't allowed (colons separate dep and template names from source prefixes).")
    expect(Dep("colons:invalidate names")).to be_nil
  end
  it "should create deps with valid names" do
    expect {
      Babushka::Dep.new("valid dep name", Babushka::Base.sources.anonymous, [], {}, nil)
    }.to change(Babushka::Base.sources.anonymous.deps, :count).by(1)
    expect(Dep("valid dep name")).to be_an_instance_of(Babushka::Dep)
  end
  it "should store the params" do
    expect {
      Babushka::Dep.new("valid dep with params", Babushka::Base.sources.anonymous, [:some, :params], {}, nil)
    }.to change(Babushka::Base.sources.anonymous.deps, :count).by(1)
    expect(Dep("valid dep with params").params).to eq([:some, :params])
  end
  context "without template" do
    before {
      @dep = Babushka::Dep.new("valid base dep", Babushka::Base.sources.anonymous, [], {}, nil)
    }
    it "should work" do
      expect(@dep).to be_an_instance_of(Babushka::Dep)
      expect(@dep.template).to eq(Babushka::Dep.base_template)
    end
  end
  context "with a missing template" do
    it "should fail to define optioned deps against a missing template" do
      expect {
        Babushka::Dep.new("valid but missing template", Babushka::Base.sources.anonymous, [], {:template => 'template'}, nil).template
      }.to raise_error(Babushka::TemplateNotFound, "There is no template named 'template' to define 'valid but missing template' against.")
    end
  end
  context "with template" do
    before {
      @meta = meta('template')
    }
    it "should work when passed as an option" do
      Babushka::Dep.new("valid option dep", Babushka::Base.sources.anonymous, [], {:template => 'template'}, nil).tap {|dep|
        expect(dep).to be_an_instance_of(Babushka::Dep)
        expect(dep.template).to eq(@meta)
      }
    end
    it "should work when passed as a suffix" do
      Babushka::Dep.new("valid dep name.template", Babushka::Base.sources.anonymous, [], {}, nil).tap {|dep|
        expect(dep).to be_an_instance_of(Babushka::Dep)
        expect(dep.template).to eq(@meta)
      }
    end
    after { Babushka::Base.sources.anonymous.templates.clear! }
  end
end

RSpec.describe '#inspect' do
  let(:source) {
    Babushka::Source.new(nil, 'test source')
  }
  it "should represent the dep and its source" do
    the_dep = Babushka::Dep.new('inspect test', source, [], {}, nil)
    expect(the_dep.inspect).to eq("#<Dep:#{the_dep.object_id} 'test source:inspect test'>")
  end
end

RSpec.describe "dep creation" do
  it "should work for blank deps" do
    expect {
      dep "a blank dep"
    }.to change(Babushka::Base.sources.anonymous.deps, :count).by(1)
    expect(Dep('a blank dep')).to be_an_instance_of(Babushka::Dep)
  end
  it "should work for filled in deps" do
    expect {
      dep "a standard dep" do
        requires 'some other dep'
        before { }
        met? { }
        meet { }
        after { }
      end
    }.to change(Babushka::Base.sources.anonymous.deps, :count).by(1)
    expect(Dep('a standard dep')).to be_an_instance_of(Babushka::Dep)
  end
  it "should accept deps as dep names" do
    expect {
      dep 'parent dep' do
        requires dep('nested dep')
      end.met?
    }.to change(Babushka::Base.sources.anonymous.deps, :count).by(2)
    expect(Dep('parent dep').context.requires).to eq([Dep('nested dep')])
  end
  after { Babushka::Base.sources.anonymous.deps.clear! }

  context "without template" do
    it "should use the base template" do
      expect(dep('without template').template).to eq(Babushka::Dep.base_template)
    end
  end
  context "with template" do
    before {
      @template = meta 'template'
    }
    it "should use the template when passed as an option" do
      dep('with template', :template => 'template').tap {|dep|
        expect(dep.template).to eq(@template)
        expect(dep).not_to be_suffixed
        expect(dep.suffix).to be_nil
      }
    end
    it "should use the template and be suffixed when passed as a suffix" do
      dep('with template.template').tap {|dep|
        expect(dep.template).to eq(@template)
        expect(dep).to be_suffixed
        expect(dep.suffix).to eq('template')
      }
    end
    context "when both are passed" do
      before {
        @another_template = meta 'another_template'
      }
      it "should use the option template" do
        dep('with both templates.template', :template => 'another_template').tap {|dep|
          expect(dep.template).to eq(@another_template)
          expect(dep).not_to be_suffixed
          expect(dep.suffix).to eq('template')
        }
      end
    end
  end
  after { Babushka::Base.sources.anonymous.templates.clear! }
end

RSpec.describe Babushka::Dep, "defining" do
  before {
    allow(Babushka::Base.sources).to receive(:current_real_load_source).and_return(Babushka::Base.sources.anonymous)
  }
  it "should not define the dep when called without a block" do
    expect(dep('lazy defining test').context).not_to be_loaded
  end
  it "should not define the dep when called with a block" do
    expect(dep('lazy defining test with block') do
      requires 'another dep'
    end.context).not_to be_loaded
  end
  context "after running" do
    it "should be defined" do
      expect(dep('lazy defining test with run').tap {|dep|
        dep.met?
      }.context).to be_loaded
    end
    context "with a template" do
      let!(:template) { meta 'lazy_defining_template' }
      it "should use the template" do
        expect(dep('lazy defining test with template.lazy_defining_template').tap {|dep|
          dep.met?
        }.template).to eq(template)
      end
    end
  end
  context "with params" do
    it "should run against subsequent parameters" do
      parameter = Babushka::Parameter.new(:arg)
      dep('parameter preserving', :arg) {
        arg.default!('a default value')
      }.tap {|dep|
        dep.met?('some other value')
        dep.met?(parameter)
      }
      expect(parameter.description).to eq('arg: [default!: "a default value"]')
    end
  end
  context "with errors" do
    before {
      allow(Babushka::Base.sources).to receive(:current_real_load_source).and_return(Babushka::Base.sources.anonymous)
    }
    it "should not be defined, and then have failed defining after a run" do
      expect(dep('lazy defining test with errors') do
        nonexistent_method
      end.tap {|dep|
        expect(dep.context).not_to be_loaded
        dep.met?
      }.context).to be_failed
    end
    it "should not attempt to run" do
      dep('lazy defining test with errors') do
        nonexistent_method
      end.tap {|dep|
        expect(dep).not_to receive(:run_requirements)
        expect(dep).not_to receive(:run_met)
      }.met?
    end
    it "should not attempt to run later" do
      dep('lazy defining test with errors') do
        nonexistent_method
      end.tap {|dep|
        dep.met?
        expect(dep).not_to receive(:run_requirements)
        expect(dep).not_to receive(:run_met)
      }.met?
    end
  end
end

RSpec.describe Babushka::Dep, '#basename' do
  context "for base deps" do
    it "should be the same as the dep's name" do
      expect(dep('basename test').basename).to eq('basename test')
    end
    context "with a suffix" do
      it "should be the same as the dep's name" do
        expect(dep('basename test.basename_test').basename).to eq('basename test.basename_test')
      end
    end
  end
  context "for option-templated deps" do
    before { meta 'basename_template' }
    it "should be the same as the dep's name" do
      expect(dep('basename test', :template => 'basename_template').basename).to eq('basename test')
    end
    context "with a suffix" do
      it "should be the same as the dep's name" do
        expect(dep('basename test.basename_template', :template => 'basename_template').basename).to eq('basename test.basename_template')
      end
    end
    after {
      Babushka::Base.sources.anonymous.deps.clear!
      Babushka::Base.sources.anonymous.templates.clear!
    }
  end
  context "for suffix-templated deps" do
    before { meta 'basename_template' }
    it "should remove the suffix name" do
      expect(dep('basename test.basename_template').basename).to eq('basename test')
    end
    after {
      Babushka::Base.sources.anonymous.deps.clear!
      Babushka::Base.sources.anonymous.templates.clear!
    }
  end
end

RSpec.describe Babushka::Dep, '#cache_key' do
  it "should work for parameterless deps" do
    expect(dep('cache key, no params').cache_key).to eq(Babushka::DepRequirement.new('cache key, no params', []))
  end
  it "should work for parameterised deps with no args" do
    expect(dep('cache key, no args', :arg1, :arg2).cache_key).to eq(Babushka::DepRequirement.new('cache key, no args', [nil, nil]))
  end
  it "should work for parameterised deps with named args" do
    expect(dep('cache key, named args', :arg1, :arg2).with(:arg2 => 'value').cache_key).to eq(Babushka::DepRequirement.new('cache key, named args', [nil, 'value']))
  end
  it "should work for parameterised deps positional args" do
    expect(dep('cache key, positional args', :arg1, :arg2).with('value', 'another').cache_key).to eq(Babushka::DepRequirement.new('cache key, positional args', ['value', 'another']))
  end
end

RSpec.describe Babushka::Dep, "params" do
  describe "non-symbol params" do
    it "should be rejected, singular" do
      expect {
        dep('non-symbol param', 'a')
      }.to raise_error(Babushka::DepParameterError, %{The dep 'non-symbol param' has a non-symbol param "a", which isn't allowed.})
    end
    it "should be rejected, plural" do
      expect {
        dep('non-symbol params', 'a', 'b')
      }.to raise_error(Babushka::DepParameterError, %{The dep 'non-symbol params' has non-symbol params "a" and "b", which aren't allowed.})
    end
  end
  it "should define methods on the context" do
    expect(dep('params test', :a_param).context.define!).to respond_to(:a_param)
  end
  it "should raise on conflicting methods" do
    expect {
      dep('conflicting param names', :name).context.define!
    }.to raise_error(Babushka::DepParameterError, "You can't use :name as a parameter (on 'conflicting param names'), because that's already a method on Babushka::DepDefiner.")
  end
  it "should discard the context" do
    dep('context discarding').tap {|dep|
      expect(dep.context).not_to eq(dep.with.context)
    }
  end
  it "should not pollute other deps" do
    dep('params test', :a_param)
    expect(Dep('params test').context.define!).to respond_to(:a_param)
    expect(dep('paramless dep').context.define!).not_to respond_to(:a_param)
  end
  it "should return a param containing the value when it's set" do
    dep('set params test', :a_set_param)
    expect(Dep('set params test').with('a value').context.define!.a_set_param).to be_an_instance_of(Babushka::Parameter)
    expect(Dep('set params test').with('a value').context.define!.a_set_param.to_s).to eq('a value')
  end
  it "should ask for the value when it's not set" do
    dep('unset params test', :an_unset_param).context.define!
    expect(Dep('unset params test').context.an_unset_param).to be_an_instance_of(Babushka::Parameter)
    expect(Babushka::Prompt).to receive(:get_value).with('an_unset_param', {}).and_return('a value from the prompt')
    expect(Dep('unset params test').context.an_unset_param.to_s).to eq('a value from the prompt')
  end
end

RSpec.describe Babushka::Dep, 'lambda lists' do
  before {
    allow(Babushka.host.matcher).to receive(:name).and_return(:test_name)
    allow(Babushka.host.matcher).to receive(:system).and_return(:test_system)
    allow(Babushka.host.matcher).to receive(:pkg_helper_key).and_return(:test_helper)

    allow(Babushka::SystemDefinition).to receive(:all_names).and_return([:test_name, :other_name])
    allow(Babushka::SystemDefinition).to receive(:all_systems).and_return([:test_system, :other_system])
    allow(Babushka::PkgHelper).to receive(:all_manager_keys).and_return([:test_helper, :other_helper])
  }
  it "should match against the system name" do
    expect(dep('lambda list name match') { requires { on :test_name, 'awesome' } }.context.define!.requires).to eq(['awesome'])
  end
  it "should match against the system type" do
    expect(dep('lambda list system match') { requires { on :test_system, 'awesome' } }.context.define!.requires).to eq(['awesome'])
  end
  it "should match against the system name" do
    expect(dep('lambda list pkg_helper_key match') { requires { on :test_helper, 'awesome' } }.context.define!.requires).to eq(['awesome'])
  end
end

RSpec.describe Babushka::Dep, '#requirements_for' do
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
    expect(requirements.length).to eq(3)
  end
  it "should return a DepRequirement for all the required deps" do
    requirements.each {|c| expect(c).to be_an_instance_of(Babushka::DepRequirement) }
  end
  it "should contain the right dep names" do
    expect(requirements.map(&:name)).to eq(['a dep', 'another dep', 'a third'])
  end
  it "should work with empty args" do
    expect(requirements[0].args).to eq([])
    expect(requirements[2].args).to eq([])
  end
  context "arguments" do
    let(:args) { requirements[1].args }
    it "should have the right number of args" do
      expect(args.length).to eq(2)
    end
    it "should contain the right args" do
      expect(args).to eq([:some, :args])
    end
  end
end

RSpec.describe "exceptions" do
  it "should be unmet after an exception in met? {}" do
    the_dep = dep 'exception met? test' do
      met? { raise }
    end

    expect(the_dep.met?).to be_falsey
  end
  it "should be unmet after an exception in meet {}" do
    the_dep = dep 'exception meet test' do
      met? { false }
      meet { raise }
    end

    expect(the_dep.met?).to be_falsey
  end
end

RSpec.describe "calling met? on a single dep" do
  it "should still call met? if setup returns falsey" do
    the_dep = dep('met? - setup is false') {
      setup { false }
    }
    should_call_dep_like(:met_run, the_dep)
    expect(the_dep).to be_met
  end
  it "should be false for unmet deps" do
    the_dep = dep('met? - unmet') {
      met? { false }
    }
    should_call_dep_like(:met_run, the_dep)
    expect(the_dep).not_to be_met
  end
  it "should be true for met deps" do
    the_dep = dep('met? - met') {
      met? { true }
    }
    should_call_dep_like(:met_run, the_dep)
    expect(the_dep).to be_met
  end
  after { Babushka::Base.sources.anonymous.deps.clear! }
end

RSpec.describe "calling meet on a single dep" do
  it "should be false for an unmeetable dep" do
    the_dep = dep('unmeetable') {
      met? { false }
    }
    should_call_dep_like(:meet_run, the_dep)
    expect(the_dep.meet).to eq(false)
  end
  it "should be nil for an explicitly unmeetable dep" do
    the_dep = dep('explicitly unmeetable') {
      met? { unmeetable! }
    }
    should_call_dep_like(:met_run, the_dep)
    expect(the_dep.meet).to eq(nil)
  end
  it "should be true for a meetable dep" do
    the_dep = dep('unmet') {
      met? { @met }
      meet { @met = true }
    }
    should_call_dep_like(:meet_run, the_dep)
    expect(the_dep.meet).to eq(true)
  end
  it "should be false for an unmet dep when before is false" do
    the_dep = dep('unmet, #before is false') {
      met? { false }
      before { false }
    }
    should_call_dep_like(:meet_skipped, the_dep)
    expect(the_dep.meet).to eq(false)
  end
  it "should be false for an unmet dep when meet fails" do
    the_dep = dep('unmet, #meet fails') {
      met? { false }
      meet { unmeetable! }
    }
    should_call_dep_like(:meet_failed, the_dep)
    expect(the_dep.meet).to eq(nil)
  end
  it "should be true for an unmet dep when after fails" do
    the_dep = dep('unmet, #after fails') {
      met? { @met }
      meet { @met = true }
      after { false }
    }
    should_call_dep_like(:meet_run, the_dep)
    expect(the_dep.meet).to eq(true)
  end
  it "should be true for an already met dep" do
    the_dep = dep('met') {
      met? { true }
    }
    should_call_dep_like(:met_run, the_dep)
    expect(the_dep.meet).to eq(true)
  end
  after { Babushka::Base.sources.anonymous.deps.clear! }
end

RSpec.describe 'dep caching' do
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
    expect(Dep('caching parent')).to receive(:run_met).once
    expect(Dep('caching child a')).to receive(:run_met).once.and_return(true)
    expect(Dep('caching child b')).to receive(:run_met).twice.and_return(true)
    expect(Dep('caching child c')).to receive(:run_met).once.and_return(true)

    Dep('caching parent').met?
  end
end

RSpec.describe "fs snapshotting" do
  before {
    allow(Babushka::Base.task).to receive(:opt).and_return(false)
    allow(Babushka::Base.task).to receive(:opt).with(:git_fs).and_return(true)
    allow(Babushka::GitFS.repo).to receive(:exists?) { true }
  }
  context "when the dep is already met" do
    let(:the_dep) {
      dep('snapshotting - met')
    }
    it "should not snapshot" do
      expect(Babushka::GitFS).not_to receive(:commit)
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
      expect(Babushka::GitFS).not_to receive(:commit)
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
      expect(the_dep).to receive(:run_meet_stage).and_call_original
      expect(Babushka::GitFS).to receive(:commit).with("babushka 'snapshotting - unmet'\n\n")
      the_dep.meet
    end
    context "when snapshotting is disabled" do
      before {
        allow(Babushka::Base.task).to receive(:opt).and_return(false)
        allow(Babushka::Base.task).to receive(:opt).with(:git_fs).and_return(false)
      }
      it "should not snapshot" do
        expect(Babushka::GitFS).not_to receive(:commit)
        the_dep.meet
      end
    end
  end
end
