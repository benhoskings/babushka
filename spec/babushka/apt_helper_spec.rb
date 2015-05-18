require 'spec_helper'

describe Babushka::AptHelper do
  let(:apt_helper) { Babushka::AptHelper }

  describe '.source_matcher_for_system' do
    let(:matcher) {
      Babushka::AptHelper.source_matcher_for_system
    }
    context 'on debian' do
      before {
        Babushka.host.stub(:flavour).and_return(:debian)
      }
      it "should match the root mirror" do
        'http://ftp.debian.org/debian'[matcher].should_not be_nil
        'http://ftp2.debian.org/debian'[matcher].should_not be_nil
      end
      it "should match country mirrors" do
        'http://ftp.au.debian.org/debian'[matcher].should_not be_nil
        'http://ftp2.au.debian.org/debian'[matcher].should_not be_nil
      end
      it "should match geoip mirrors" do
        'http://http.debian.net/debian'[matcher].should_not be_nil
        'http://cdn.debian.net/debian'[matcher].should_not be_nil
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
        Babushka.host.stub(:flavour).and_return(:ubuntu)
      }
      it "should match the root mirror" do
        'http://archive.ubuntu.com/ubuntu'[matcher].should_not be_nil
      end
      it "should match country mirrors" do
        'http://au.archive.ubuntu.com/ubuntu'[matcher].should_not be_nil
      end
      it "should match ec2 mirrors" do
        'http://us-east-1.ec2.archive.ubuntu.com/ubuntu/'[matcher].should_not be_nil
        'http://us-west-1.ec2.archive.ubuntu.com/ubuntu/'[matcher].should_not be_nil
        'http://ap-southeast-1.ec2.archive.ubuntu.com/ubuntu/'[matcher].should_not be_nil
      end
      it "should match with a trailing slash" do
        'http://archive.ubuntu.com/ubuntu/'[matcher].should_not be_nil
      end
      it "should not match other things" do
        'http://archive.ubuntu.com/'[matcher].should be_nil
        'http://lolarchive.ubuntu.com/ubuntu'[matcher].should be_nil
        'http://babushka.me'[matcher].should be_nil
        'http://us-east-1.ec3.archive.ubuntu.com/ubuntu/'[matcher].should be_nil
        'http://.ec2.archive.ubuntu.com/ubuntu/'[matcher].should be_nil
        'http://ec2.archive.ubuntu.com/ubuntu/'[matcher].should be_nil
        'http://lolec2.archive.ubuntu.com/ubuntu/'[matcher].should be_nil
        'http://lol.ec2.archive.ubuntu.com/ubuntu/'[matcher].should be_nil
      end
    end
    context 'on raspbian' do
      before {
        Babushka.host.stub(:flavour).and_return(:raspbian)
      }
      it "should match the root mirror" do
        'http://archive.raspbian.org/raspbian'[matcher].should_not be_nil
      end
      it "should match the mirror director" do
        'http://mirrordirector.raspbian.org/raspbian'[matcher].should_not be_nil
      end
      it "should match a trailing slash" do
        'http://mirrordirector.raspbian.org/raspbian/'[matcher].should_not be_nil
      end
      it "should not match other things" do
        'http://ec2.archive.ubuntu.com/ubuntu/'[matcher].should be_nil
      end
    end
  end
end
