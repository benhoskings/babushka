require 'spec_support'
require 'dep_support'

describe "Dep.make" do
  it "should reject deps with nonprintable characters in their names" do
    L{
      Dep.make "carriage\rreturn", Base.sources.anonymous, {}, nil
    }.should raise_error DepError, "The dep name 'carriage\rreturn' contains nonprintable characters."
    Dep("carriage\rreturn").should be_nil
  end
  it "should reject deps slashes in their names" do
    L{
      Dep.make "slashes/invalidate names", Base.sources.anonymous, {}, nil
    }.should raise_error DepError, "The dep name 'slashes/invalidate names' contains '/', which isn't allowed."
    Dep("slashes/invalidate names").should be_nil
  end
  it "should create deps with valid names" do
    L{
      Dep.make("valid dep name", Base.sources.anonymous, {}, nil).should be_an_instance_of(Dep)
    }.should change(Base.sources.anonymous, :count).by(1)
    Dep("valid dep name").should be_an_instance_of Dep
  end
  context "without template" do
    before {
      @dep = Dep.make("valid base dep", Base.sources.anonymous, {}, nil)
    }
    it "should work" do
      @dep.should be_an_instance_of Dep
      @dep.template.should == Dep::BaseTemplate
    end
  end
  context "with template" do
    it "should fail to create optioned deps against a missing template" do
      L{
        Dep.make("valid but missing template", Base.sources.anonymous, {:template => 'template'}, nil)
      }.should raise_error DepError, "There is no template named 'template' to define 'valid but missing template' against."
    end
    context "with template from options" do
      before {
        @meta = meta('option template')
        @dep = Dep.make("valid option dep", Base.sources.anonymous, {:template => 'option template'}, nil)
      }
      it "should work" do
        @dep.should be_an_instance_of Dep
        @dep.template.should == @meta
      end
    end
    context "with template from suffix" do
      before {
        @meta = meta('.suffix_template')
        @dep = Dep.make("valid dep name.suffix_template", Base.sources.anonymous, {}, nil)
      }
      it "should work" do
        @dep.should be_an_instance_of Dep
        @dep.template.should == @meta
      end
    end
    after { Base.sources.anonymous.templates.clear! }
  end
end

describe "dep creation" do
  it "should work for blank deps" do
    L{
      dep "blank"
    }.should change(Base.sources.anonymous, :count).by(1)
    Dep('blank').should be_an_instance_of(Dep)
  end
  it "should work for filled in deps" do
    L{
      dep "standard" do
        requires 'blank'
        before { }
        met? { }
        meet { }
        after { }
      end
    }.should change(Base.sources.anonymous, :count).by(1)
    Dep('standard').should be_an_instance_of(Dep)
  end
  it "should accept deps as dep names" do
    L{
      dep 'parent dep' do
        requires dep('nested dep')
      end
    }.should change(Base.sources.anonymous, :count).by(2)
    Dep('parent dep').definer.requires.should == [Dep('nested dep')]
  end
  after { Base.sources.anonymous.deps.clear! }

  context "without template" do
    before { dep 'without template' }
    it "should use the base template" do
      Dep('without template').template.should == Dep::BaseTemplate
    end
  end
  context "with option template" do
    before {
      @template = meta 'option template'
    }
    it "should use the specified template as an option" do
      dep('with option template', :template => 'option template').template.should == @template
    end
    it "should not recognise the template as a suffix" do
      dep('with option template.option template').template.should == Dep::BaseTemplate
    end
  end
  context "with suffix template" do
    before {
      @template = meta '.suffix_template'
    }
    context "as option template" do
      before {
        @dep = dep('with suffix template', :template => 'suffix_template')
      }
      it "should use the specified template as an option" do
        @dep.template.should == @template
      end
      it "should not be suffixed" do
        @dep.should_not be_suffixed
        @dep.suffix.should be_nil
      end
    end
    context "as suffix template" do
      before {
        @dep = dep('with suffix template.suffix_template')
      }
      it "should use the specified template as a suffix" do
        @dep.template.should == @template
      end
      it "should not be suffixed" do
        @dep.should be_suffixed
        @dep.suffix.should == 'suffix_template'
      end
    end
  end
  context "with both templates" do
    before {
      meta '.suffix_template'
      @template = meta 'option template'
    }
    it "should use the option template" do
      dep('with both templates.suffix_template', :template => 'option template').template.should == @template
    end
  end
  after { Base.sources.anonymous.templates.clear! }
end

describe Dep, "defining" do
  it "should define the dep when called without a block" do
    dep('defining test').should be_dep_defined
  end
  it "should define the dep when called with a block" do
    dep('defining test with block') do
      requires 'another dep'
    end.should be_dep_defined
  end
  context "with delayed defining" do
    it "should not define the dep when called without a block" do
      dep('delayed defining test', :delay_defining => true).should_not be_dep_defined
    end
    it "should not define the dep when called with a block" do
      dep('delayed defining test with block', :delay_defining => true) do
        requires 'another dep'
      end.should_not be_dep_defined
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
    before { meta 'basename template' }
    it "should be the same as the dep's name" do
      dep('basename test', :template => 'basename template').basename.should == 'basename test'
    end
    context "with a suffix" do
      it "should be the same as the dep's name" do
        dep('basename test.basename template', :template => 'basename template').basename.should == 'basename test.basename template'
      end
    end
    after { Base.sources.anonymous.templates.clear! }
  end
  context "for suffix-templated deps" do
    before { meta 'basename_template' }
    it "should remove the suffix name" do
      dep('basename test.basename_template').basename.should == 'basename test'
    end
    after { Base.sources.anonymous.templates.clear! }
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

describe "calling meet on a single dep" do
  before {
    setup_yield_counts
  }
  it "should fail twice on unmeetable deps" do
    make_counter_dep(
      :name => 'unmeetable', :met? => L{ false }
    ).meet.should == false
    @yield_counts['unmeetable'].should == @yield_counts_meet_run
  end
  it "should fail, run meet, and then succeed on unmet deps" do
    make_counter_dep(
      :name => 'unmet', :met? => L{ !@yield_counts['unmet'][:met?].zero? }
    ).meet.should == true
    @yield_counts['unmet'].should == @yield_counts_meet_run
  end
  it "should fail, not run meet, and fail again on unmet deps where before fails" do
    make_counter_dep(
      :name => 'unmet, #before fails', :met? => L{ false }, :before => L{ false }
    ).meet.should == false
    @yield_counts['unmet, #before fails'].should == @yield_counts_failed_at_before
  end
  it "should fail, run meet, and then succeed on unmet deps where after fails" do
    make_counter_dep(
      :name => 'unmet, #after fails', :met? => L{ !@yield_counts['unmet, #after fails'][:met?].zero? }, :after => L{ false }
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

describe "run_in" do
  it "should run in the current directory when run_in isn't set" do
    cwd = Dir.pwd
    ran_in = nil
    dep 'dep without run_in set' do
      met? { ran_in = Dir.pwd }
    end.met?
    Dir.pwd.should == cwd
    ran_in.should == cwd
  end
  it "should fail when run_in is set to a nonexistent directory" do
    L{
      dep 'dep with run_in set to a nonexistent dir' do
        run_in (tmp_prefix / 'nonexistent').to_s
      end.met?
    }.should raise_error Errno::ENOENT, "No such file or directory - #{tmp_prefix / 'nonexistent'}"
  end
  it "should run in the specified directory when run_in is set" do
    cwd = Dir.pwd
    ran_in = nil
    dep 'dep with run_in set' do
      run_in tmp_prefix
      met? { ran_in = Dir.pwd }
    end.met?
    Dir.pwd.should == cwd
    ran_in.should == tmp_prefix
  end
  it "should run this deps' requirements in the same directory" do
    cwd = Dir.pwd
    ran_in = child_ran_in = nil
    dep 'another without run_in set' do
      met? { child_ran_in = Dir.pwd }
    end
    dep 'dep with run_in set' do
      requires 'another without run_in set'
      run_in tmp_prefix
      met? { ran_in = Dir.pwd }
    end.met?
    Dir.pwd.should == cwd
    ran_in.should == tmp_prefix
    child_ran_in.should == tmp_prefix
  end
  it "should run this deps' requirements in their own directories when specified" do
    cwd = Dir.pwd
    ran_in = child_ran_in = nil
    (tmp_prefix / 'run_in').mkdir
    dep 'another without run_in set' do
      run_in tmp_prefix / 'run_in'
      met? { child_ran_in = Dir.pwd }
    end
    dep 'dep with run_in set' do
      requires 'another without run_in set'
      run_in tmp_prefix
      met? { ran_in = Dir.pwd }
    end.met?
    Dir.pwd.should == cwd
    ran_in.should == tmp_prefix
    child_ran_in.should == tmp_prefix / 'run_in'
  end
  after { Base.sources.anonymous.deps.clear! }
end
