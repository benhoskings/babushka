require 'spec_helper'

RSpec.describe "console" do
  before {
    entry_point = File.expand_path(File.join(__FILE__, '../../../../lib/babushka'))
    expect(Babushka::Cmdline).to receive(:exec).with("irb -r'#{entry_point}' --simple-prompt")
  }
  it "should launch a console via Kernel#exec" do
    Babushka::Cmdline::Parser.for(%w[console]).run
  end
end
