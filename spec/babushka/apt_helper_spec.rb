require 'spec_helper'

describe Babushka::AptHelper do
  let(:apt_helper) { Babushka::AptHelper }

  describe '.source_matcher_for_system' do
    context 'on ubuntu' do
      let(:matcher) {
        Babushka::AptHelper.source_matcher_for_system
      }
      before {
        Babushka.host.stub!(:flavour).and_return(:ubuntu)
      }
      it "should match the root mirror" do
        'http://archive.ubuntu.com/ubuntu'[matcher].should_not be_nil
      end
      it "should match country mirrors" do
        'http://au.archive.ubuntu.com/ubuntu'[matcher].should_not be_nil
      end
      it "should match with a trailing slash" do
        'http://archive.ubuntu.com/ubuntu/'[matcher].should_not be_nil
      end
      it "should not match other things" do
        'http://archive.ubuntu.com/'[matcher].should be_nil
        'http://lolarchive.ubuntu.com/ubuntu'[matcher].should be_nil
        'http://babushka.me'[matcher].should be_nil
      end
    end
  end
end
