require 'spec_helper'

describe Babushka::AptHelper do
  let(:apt_helper) { Babushka::AptHelper }

  describe '.source_matcher_for_system' do
    let(:matcher) {
      Babushka::AptHelper.source_matcher_for_system
    }
    context 'on debian' do
      before {
        Babushka.host.stub!(:flavour).and_return(:debian)
      }
      it "should match the root mirror" do
        'http://ftp.debian.org/debian'[matcher].should_not be_nil
        'http://ftp2.debian.org/debian'[matcher].should_not be_nil
      end
      it "should match country mirrors" do
        'http://ftp.au.debian.org/debian'[matcher].should_not be_nil
        'http://ftp2.au.debian.org/debian'[matcher].should_not be_nil
      end
      it "should match with a trailing slash" do
        'http://ftp.debian.org/debian/'[matcher].should_not be_nil
      end
      it "should not match other things" do
        'http://ftp.debian.org/'[matcher].should be_nil
        'http://lolftp.debian.org/debian'[matcher].should be_nil
        'http://babushka.me'[matcher].should be_nil
      end
    end
    context 'on ubuntu' do
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
