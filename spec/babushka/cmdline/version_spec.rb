require 'spec_helper'

describe "version" do
  it "should print the version" do
    Base.should_receive(:log).with(VERSION)
    Base.run ['version']
  end
end
