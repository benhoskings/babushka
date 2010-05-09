require 'spec_support'
require 'sources_support'

describe SourcePool, '#source_for' do
  before {
    @source_pool = SourcePool.new
    @source = test_dep_source 'clone_test'
  }
  it "should add the source if it's not in the pool" do
    L{
      @source_pool.source_for(*@source)
    }.should change(@source_pool, :count).by(1)
  end
  it "should return the existing source if it's in the pool" do
    source = @source_pool.source_for(*@source)
    new_source = nil
    L{
      new_source = @source_pool.source_for(*@source)
    }.should_not change(@source_pool, :count)
    source.should == new_source
  end
end
