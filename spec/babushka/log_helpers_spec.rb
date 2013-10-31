require 'spec_helper'

describe '#log' do
  describe 'unicode handling' do
    it "should handle messages with bad encodings" do
      Babushka::Logging.should_receive(:print_log).with(Babushka::Logging.indentation, true, nil)
      Babushka::Logging.should_receive(:print_log).with("l??l\n", true, nil)
      Babushka::LogHelpers.log('lól'.force_encoding('ascii'))
    end
  end
end
