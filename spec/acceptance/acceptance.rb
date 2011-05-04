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
    context "core deps" do
      it "should update rubygems" do
        @vm.should meet('rubygems')
      end
      it "should install build tools" do
        @vm.should meet('build tools')
      end
    end

    context "some of my deps" do
      it "should configure the system" do
        @vm.babushka('benhoskings:system') # once to set the locale
        @vm.should meet('benhoskings:system')
      end
      it "should build ruby 1.9" do
        @vm.should meet('benhoskings:ruby19.src')
      end
      it "should set up nginx" do
        @vm.should meet('benhoskings:webserver running.nginx')
      end
    end

    # It's important to have a wide range of deps here, so please suggest
    # stable deps of your own that I can add to the list. The intention isn't
    # to run every dep ever, just a representative set that together cover
    # babushka's scope.
    context "community deps" do
      it "should build node and coffee-script" do
        @vm.should meet('dgoodlad:coffeescript.src')
      end
    end
  end
end
