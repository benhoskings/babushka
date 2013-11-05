require 'spec_helper'

describe "version" do
  before {
    Babushka::Cmdline::Helpers.should_receive(:log).with("#{Babushka::VERSION} (#{Babushka::Base.ref})")
  }
  it "should print the version" do
    Babushka::Cmdline::Parser.for(%w[version]).run
  end
end
