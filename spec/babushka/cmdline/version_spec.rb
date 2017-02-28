require 'spec_helper'

RSpec.describe "version" do
  context "in a git repo" do
    it "should print the version and ref" do
      allow(Babushka::Base).to receive(:ref) { "f007e2c8" }
      expect(Babushka::Cmdline::Helpers).to receive(:log).with("#{Babushka::VERSION} (f007e2c8)")
      Babushka::Cmdline::Parser.for(%w[version]).run
    end
  end
  context "in a non-git directory" do
    it "should print the version alone" do
      allow(Babushka::Base).to receive(:ref) { nil }
      expect(Babushka::Cmdline::Helpers).to receive(:log).with("#{Babushka::VERSION}")
      Babushka::Cmdline::Parser.for(%w[version]).run
    end
  end
end
