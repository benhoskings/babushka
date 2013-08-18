require 'spec_helper'

describe Babushka::ImplicitSource do

  describe '#initialize' do
    it "should require a name" do
      expect { ImplicitSource.new(nil) }.to raise_error(ArgumentError, "Implicit sources require a name.")
    end
    it "should accept the supplied name" do
      Source.new('name').name.should == 'name'
    end
  end

  describe '#type' do
    it "should be :implicit" do
      ImplicitSource.new('name').type.should == :implicit
    end
  end

  describe Source, '#path' do
    it "should be nil" do
      ImplicitSource.new('name').path.should == nil
    end
  end

  describe Source, '#present?' do
    it "should be false" do
      ImplicitSource.new('name').should_not be_present
    end
  end

  describe Source, '#cloneable?' do
    it "should not be cloneable" do
      ImplicitSource.new('name').should_not be_cloneable
    end
  end

  describe "#cloned?" do
    it "should not be cloned" do
      Source.new('name').should_not be_cloned
    end
  end

end
