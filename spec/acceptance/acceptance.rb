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
      @vm.run('babushka').should =~ /Babushka v[\d.]+, \(c\) \d+ Ben Hoskings/
    end
  end
end
