require 'spec_helper'

RSpec.describe Babushka::AptHelper do
  let(:apt_helper) { Babushka::AptHelper }

  describe '.source_matcher_for_system' do
    let(:matcher) {
      Babushka::AptHelper.source_matcher_for_system
    }
    context 'on debian' do
      before {
        allow(Babushka.host).to receive(:flavour).and_return(:debian)
      }
      it "should match the root mirror" do
        expect('http://ftp.debian.org/debian'[matcher]).not_to be_nil
        expect('http://ftp2.debian.org/debian'[matcher]).not_to be_nil
      end
      it "should match country mirrors" do
        expect('http://ftp.au.debian.org/debian'[matcher]).not_to be_nil
        expect('http://ftp2.au.debian.org/debian'[matcher]).not_to be_nil
      end
      it "should match geoip mirrors" do
        expect('http://http.debian.net/debian'[matcher]).not_to be_nil
        expect('http://cdn.debian.net/debian'[matcher]).not_to be_nil
      end
      it "should match with a trailing slash" do
        expect('http://ftp.debian.org/debian/'[matcher]).not_to be_nil
      end
      it "should not match other things" do
        expect('http://ftp.debian.org/'[matcher]).to be_nil
        expect('http://lolftp.debian.org/debian'[matcher]).to be_nil
        expect('http://babushka.me'[matcher]).to be_nil
      end
    end
    context 'on ubuntu' do
      before {
        allow(Babushka.host).to receive(:flavour).and_return(:ubuntu)
      }
      it "should match the root mirror" do
        expect('http://archive.ubuntu.com/ubuntu'[matcher]).not_to be_nil
      end
      it "should match country mirrors" do
        expect('http://au.archive.ubuntu.com/ubuntu'[matcher]).not_to be_nil
      end
      it "should match ec2 mirrors" do
        expect('http://us-east-1.ec2.archive.ubuntu.com/ubuntu/'[matcher]).not_to be_nil
        expect('http://us-west-1.ec2.archive.ubuntu.com/ubuntu/'[matcher]).not_to be_nil
        expect('http://ap-southeast-1.ec2.archive.ubuntu.com/ubuntu/'[matcher]).not_to be_nil
      end
      it "should match with a trailing slash" do
        expect('http://archive.ubuntu.com/ubuntu/'[matcher]).not_to be_nil
      end
      it "should not match other things" do
        expect('http://archive.ubuntu.com/'[matcher]).to be_nil
        expect('http://lolarchive.ubuntu.com/ubuntu'[matcher]).to be_nil
        expect('http://babushka.me'[matcher]).to be_nil
        expect('http://us-east-1.ec3.archive.ubuntu.com/ubuntu/'[matcher]).to be_nil
        expect('http://.ec2.archive.ubuntu.com/ubuntu/'[matcher]).to be_nil
        expect('http://ec2.archive.ubuntu.com/ubuntu/'[matcher]).to be_nil
        expect('http://lolec2.archive.ubuntu.com/ubuntu/'[matcher]).to be_nil
        expect('http://lol.ec2.archive.ubuntu.com/ubuntu/'[matcher]).to be_nil
      end
    end
    context 'on raspbian' do
      before {
        allow(Babushka.host).to receive(:flavour).and_return(:raspbian)
      }
      it "should match the root mirror" do
        expect('http://archive.raspbian.org/raspbian'[matcher]).not_to be_nil
      end
      it "should match the mirror director" do
        expect('http://mirrordirector.raspbian.org/raspbian'[matcher]).not_to be_nil
      end
      it "should match a trailing slash" do
        expect('http://mirrordirector.raspbian.org/raspbian/'[matcher]).not_to be_nil
      end
      it "should not match other things" do
        expect('http://ec2.archive.ubuntu.com/ubuntu/'[matcher]).to be_nil
      end
    end
  end
end
