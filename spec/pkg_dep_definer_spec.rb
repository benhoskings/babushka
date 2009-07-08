require 'spec/spec_support'
require 'spec/pkg_dep_definer_support'

describe "accepts_hash_for default values" do
  before {
    setup_test_deps
  }

  it "should default installs and provides to the package name" do
    Dep('default').definer.installs.should == ['default']
    Dep('default').definer.provides.should == ['default']
  end

  after {
    Dep.clear!
  }
end
