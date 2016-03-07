require 'acceptance_helper'

describe "babushka" do
  before(:all) {
    @vm = VM.new
    @vm.run 'sh -c "`wget -O - https://babushka.me/up`"'
  }

  context "basics" do
    it "should have installed babushka" do
      expect(@vm.run('babushka --version')).to match(/^[\d.]+ \(\w{7}\)$/)
    end
  end

  context "core deps" do
    it "should install build tools" do
      expect(@vm).to meet('build tools')
    end
  end

  context "some of my deps" do
    it "should configure the system" do
      @vm.babushka('benhoskings:system') # once to set the locale
      expect(@vm).to meet('benhoskings:system')
    end
    it "should build a recent ruby" do
      expect(@vm).to meet('benhoskings:ruby.src')
    end
    it "should set up nginx" do
      expect(@vm).to meet('benhoskings:running.nginx')
    end
  end

  # It's important to have a wide range of deps here, so please suggest
  # stable deps of your own that I can add to the list. The intention isn't
  # to run every dep ever, just a representative set that together cover
  # babushka's scope.
  context "community deps" do
    it "should build node and coffee-script" do
      expect(@vm).to meet('dgoodlad:coffeescript.src')
    end
  end
end
