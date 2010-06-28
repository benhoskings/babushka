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
