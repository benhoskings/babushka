require 'spec_support'
require 'dep_support'

describe "Dep.make" do
  it "should reject deps with nonprintable characters in their names" do
    L{
      Dep.make "carriage\rreturn", Base.sources.default, {}, nil
    }.should raise_error DepError, "The dep name 'carriage\rreturn' contains nonprintable characters."
    Dep("carriage\rreturn").should be_nil
  end
  it "should reject deps slashes in their names" do
    L{
      Dep.make "slashes/invalidate names", Base.sources.default, {}, nil
    }.should raise_error DepError, "The dep name 'slashes/invalidate names' contains '/', which isn't allowed."
    Dep("slashes/invalidate names").should be_nil
  end
  it "should create deps with valid names" do
    L{
      Dep.make("valid dep name", Base.sources.default, {}, nil).should be_an_instance_of(Dep)
    }.should change(Base.sources.default, :count).by(1)
    Dep("valid dep name").should be_an_instance_of Dep
  end
  context "without template" do
    before {
      @dep = Dep.make("valid base dep", Base.sources.default, {}, nil)
    }
    it "should work" do
      @dep.should be_an_instance_of Dep
      @dep.template.should == Dep::BaseTemplate
    end
  end
  context "with template" do
    it "should fail to create optioned deps against a missing template" do
      L{
        Dep.make("valid dep name", Base.sources.default, {:template => 'template'}, nil)
      }.should raise_error DepError, "There is no template named 'template' to define 'valid dep name' against."
    end
    context "with template from options" do
      before {
        @meta = meta('option template')
        @dep = Dep.make("valid option dep", Base.sources.default, {:template => 'option template'}, nil)
      }
      it "should work" do
        @dep.should be_an_instance_of Dep
        @dep.template.should == @meta
      end
    end
    context "with template from suffix" do
      before {
        @meta = meta('.suffix_template')
        @dep = Dep.make("valid dep name.suffix_template", Base.sources.default, {}, nil)
      }
      it "should work" do
        @dep.should be_an_instance_of Dep
        @dep.template.should == @meta
      end
    end
    after { Base.sources.default.templates.clear! }
  end
end

describe "dep creation" do
  it "should work for blank deps" do
    L{
      dep "blank"
    }.should change(Base.sources.default, :count).by(1)
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
    }.should change(Base.sources.default, :count).by(1)
    Dep('standard').should be_an_instance_of(Dep)
  end
  it "should accept deps as dep names" do
    L{
      dep 'parent dep' do
        requires dep('nested dep')
      end
    }.should change(Base.sources.default, :count).by(2)
    Dep('parent dep').definer.requires.should == [Dep('nested dep')]
  end
  after { Base.sources.default.deps.clear! }

  context "without template" do
    before { dep 'without template' }
    it "should use the base template" do
      Dep('without template').template.should == Dep::BaseTemplate
    end
  end
  context "with option template" do
    before {
      @template = meta 'option template'
      dep 'with option template', :template => 'option template'
    }
    it "should use the specified template" do
      Dep('option template').template.should == @template
    end
  end
  context "with suffix template" do
    before {
      @template = meta '.suffix_template'
      dep 'with suffix template', :template => 'suffix template'
    }
    it "should use the specified template" do
      Dep('suffix template').template.should == @template
    end
  end
  after { Base.sources.default.templates.clear! }
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
  after { Base.sources.default.deps.clear! }
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
  after { Base.sources.default.deps.clear! }
end
