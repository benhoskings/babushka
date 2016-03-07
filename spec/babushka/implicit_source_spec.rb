require 'spec_helper'

describe Babushka::ImplicitSource do

  describe '#initialize' do
    it "should require a name" do
      expect { Babushka::ImplicitSource.new(nil) }.to raise_error(ArgumentError, "Implicit sources require a name.")
    end
    it "should accept the supplied name" do
      expect(Babushka::Source.new('name').name).to eq('name')
    end
  end

  describe '#type' do
    it "should be :implicit" do
      expect(Babushka::ImplicitSource.new('name').type).to eq(:implicit)
    end
  end

  describe Babushka::ImplicitSource, '#path' do
    it "should be nil" do
      expect(Babushka::ImplicitSource.new('name').path).to eq(nil)
    end
  end

  describe Babushka::ImplicitSource, '#present?' do
    it "should be false" do
      expect(Babushka::ImplicitSource.new('name')).not_to be_present
    end
  end

  describe Babushka::ImplicitSource, '#remote?' do
    it "should not be remote" do
      expect(Babushka::ImplicitSource.new('name')).not_to be_remote
    end
  end

end
