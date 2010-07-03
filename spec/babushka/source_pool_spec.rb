require 'spec_support'
require 'sources_support'

describe SourcePool, '#dep_for' do
  before {
    @source1 = Source.new nil, :name => 'source_1'
    @source1.stub!(:load!)
    @source2 = Source.new nil, :name => 'source_2'
    @source2.stub!(:load!)
    DepDefiner.load_context :source => @source1 do
      @dep1 = dep 'dep 1'
      @dep2 = dep 'dep 2'
    end
    DepDefiner.load_context :source => @source2 do
      @dep3 = dep 'dep 3'
      @dep4 = dep 'dep 4'
    end
    Base.sources.stub!(:current).and_return([@source1, @source2])
    Source.stub!(:present).and_return([@source1, @source2])
  }
  it "should look up the correct deps without namespacing" do
    Base.sources.dep_for('dep 1').should == @dep1
    Base.sources.dep_for('dep 4').should == @dep4
  end
  it "should find the dep when the namespace is correct" do
    Base.sources.dep_for('source_1:dep 1').should == @dep1
    Base.sources.dep_for('source_2:dep 4').should == @dep4
  end
  it "should not find the dep when the namespace is wrong" do
    Base.sources.dep_for('source_1:dep 3').should be_nil
    Base.sources.dep_for('source_2:dep 2').should be_nil
  end
end

describe SourcePool, '#template_for' do
  before {
    @source1 = Source.new nil, :name => 'source_1'
    @source2 = Source.new nil, :name => 'source_2'
    [Base.sources.anonymous, Base.sources.core, @source1, @source2].each {|s| s.stub!(:load!) }
    Source.stub!(:present).and_return [@source1, @source2]

    DepDefiner.load_context :source => Base.sources.anonymous do
      @anonymous_meta = meta 'anonymous meta'
    end
    DepDefiner.load_context :source => Base.sources.core do
      @core_meta = meta 'core meta'
    end
    DepDefiner.load_context :source => @source1 do
      @meta1 = meta 'meta 1'
      @meta2 = meta 'meta 2'
    end
    DepDefiner.load_context :source => @source2 do
      @meta3 = meta 'meta 3'
      @meta4 = meta 'meta 4'
    end
  }
  context "without namespacing" do
    it "should find templates in the anonymous source" do
      Base.sources.template_for('anonymous meta').should == @anonymous_meta
    end
    it "should find templates in the core source" do
      Base.sources.template_for('core meta').should == @core_meta
    end
    it "should not find templates from non-default sources" do
      Base.sources.template_for('meta 1').should be_nil
      Base.sources.template_for('meta 3').should be_nil
    end
  end
  context "with namespacing" do
    it "should find the dep when the namespace is correct" do
      Base.sources.template_for('source_1:meta 1').should == @meta1
      Base.sources.template_for('source_2:meta 4').should == @meta4
    end
    it "should not find the dep when the namespace is wrong" do
      Base.sources.template_for('source_1:meta 3').should be_nil
      Base.sources.template_for('source_2:meta 2').should be_nil
    end
  end
  after {
    Base.sources.anonymous.templates.clear!
    Base.sources.core.templates.clear!
  }
end
