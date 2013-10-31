# coding: utf-8

require 'spec_helper'

describe '#log' do
  describe 'unicode handling' do
    if "".respond_to?(:encoding) # Skip these tests on ruby-1.8.

      it "should handle messages with bad encodings" do
        Babushka::Logging.should_receive(:print_log).with(Babushka::Logging.indentation, true, nil)
        Babushka::Logging.should_receive(:print_log).with("l??l\n", true, nil)
        Babushka::LogHelpers.log('lól'.force_encoding('ascii'))
      end

    end
  end
end
