# coding: utf-8

require 'spec_helper'

RSpec.describe '#log' do
  describe 'unicode handling' do
    if "".respond_to?(:encoding) # Skip these tests on ruby-1.8.

      it "should handle messages with bad encodings" do
        expect(Babushka::Logging).to receive(:print_log).with(Babushka::Logging.indentation, true, nil)
        expect(Babushka::Logging).to receive(:print_log).with("l??l\n", true, nil)
        Babushka::LogHelpers.log('lól'.force_encoding('ascii'))
      end

    end
  end
end
