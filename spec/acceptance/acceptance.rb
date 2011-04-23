require 'acceptance_helper'

describe "babushka" do
  before(:all) {
    @vm = VM.instance
  }
  context "bootstrapping" do
    before(:all) {
      @vm.run 'bash -c "`wget -O - babushka.me/up/hard`"'
    }
    it "should have installed babushka" do
      @vm.run('babushka --version').should =~ /^[\d.]+$/
    end

    # Between installing babushka itself and these specs, the core
    # set of deps is pretty much covered.
    context "running core deps" do
      it "should update rubygems" do
        @vm.should meet('rubygems')
      end
      it "should install build tools" do
        @vm.should meet('build tools')
      end
    end
  end
end
