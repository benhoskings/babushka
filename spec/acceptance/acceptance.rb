# coding: utf-8

require 'acceptance_helper'

describe "babushka" do
  before(:all) {
    @vm = VM.instance
    @vm.run 'apt-get install -qqy curl'
  }
  context "bootstrapping" do
    before(:all) {
      @vm.run 'bash -c "`curl babushka.me/up/hard`"'
    }
    it "should have installed babushka" do
      @vm.run('babushka --version').should =~ /^[\d.]+$/
    end
    context "running basic deps" do
      it "should update rubygems" do
        @vm.babushka('rubygems').should =~ /^\} ✓ rubygems/
      end
    end
  end
end
