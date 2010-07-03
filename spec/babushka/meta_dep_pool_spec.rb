require 'spec_support'

describe MetaDepPool, '#for_dep' do
  before {
    meta 'meta_dep_pool_test'
    dep 'meta_dep_pool_dep 1'
    dep 'meta_dep_pool_dep 2.meta_dep_pool_other'
    dep 'meta_dep_pool_dep 3.meta_dep_pool_test'
    @pool = Base.sources.anonymous.templates
  }
  it "should return nil for nonexistent deps" do
    @pool.for_dep('meta_dep_pool_dep 0').should be_nil
  end
  it "should return nil for non-suffixed deps" do
    @pool.for_dep('meta_dep_pool_dep 1').should be_nil
  end
  it "should return nil for nonexistent meta deps" do
    @pool.for_dep('meta_dep_pool_dep 2.meta_dep_pool_other').should be_nil
  end
  it "should return the meta dep" do
    @pool.for_dep('meta_dep_pool_dep 3.meta_dep_pool_test').should be_an_instance_of MetaDepWrapper
  end
  after {
    Base.sources.anonymous.deps.clear!
    Base.sources.anonymous.templates.clear!
  }
end
