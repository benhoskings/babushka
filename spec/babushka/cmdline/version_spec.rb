require 'spec_helper'

describe "version" do
  before {
    Cmdline::Helpers.should_receive(:log).with(Babushka::VERSION)
  }
  it "should print the version" do
    Cmdline::Parser.for(%w[version]).run
  end
end
