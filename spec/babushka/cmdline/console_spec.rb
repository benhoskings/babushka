require 'spec_helper'

describe "console" do
  it "should launch a console with Kernel#exec" do
    Object.stub!(:exec)
    project_root = File.dirname(File.dirname(File.dirname(File.dirname(__FILE__))))
    Object.should_receive(:exec).with("irb -r'#{File.join(project_root, 'lib/babushka')}' --simple-prompt")
    Base.run ['console']
  end
end
