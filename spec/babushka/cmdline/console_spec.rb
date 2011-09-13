require 'spec_helper'

describe "console" do
  before {
    entry_point = File.expand_path(File.join(__FILE__, '../../../../lib/babushka'))
    Cmdline.should_receive(:exec).with("irb -r'#{entry_point}' --simple-prompt")
  }
  it "should launch a console via Kernel#exec" do
    Cmdline::Parser.for(%w[console]).run
  end
end
