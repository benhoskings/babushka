require 'spec_helper'

RSpec.describe Babushka::DepCache do
  let(:dep_cache) { Babushka::DepCache.new }

  context 'when the key misses' do
    it "should yield the block to get the result" do
      expect(dep_cache.read(:miss) { 'cached result' }).to eq('cached result')
    end
    it "should not yield #hit" do
      hit = false
      dep_cache.read(:miss, :hit => lambda{ hit = true }) { 'a miss' }
      expect(hit).to be_falsey
    end
  end

  context 'when the key hits' do
    it "should return the cached result" do
      dep_cache.read(:hit) { 'cached result' }
      expect(dep_cache.read(:hit) { 'never called' }).to eq('cached result')
    end
    it "should not yield the block a second time" do
      calls = 0
      dep_cache.read(:hit) { 'cached result' }
      dep_cache.read(:hit) { calls += 1 }
      expect(calls).to eq(0)
    end
    it "should yield #hit, passing the cached value" do
      hit = false
      dep_cache.read(:hit) { 'cached result' }
      dep_cache.read(:hit, :hit => lambda{|value| hit = value }) { 'never called' }
      expect(hit).to eq('cached result')
    end
  end

end
