require 'spec/spec_support'
require 'spec/dep_definer_support'
require 'spec/pkg_dep_definer_support'
require 'spec/gem_dep_definer_support'

describe "accepts_hash_for default values" do
  before {
    make_test_pkgs :gem
    make_test_gems
  }

  it "should handle versions" do
    Dep('default gem').definer.installs.should == [ver('default gem')]
    Dep('single gem with version').definer.installs.should == [ver('gem1', '1.2.3')]
    Dep('multiple gems with version').definer.installs.should == [ver('gem2', '0.1.4'), ver('gem3', '0.2.5.1')]
  end

  after {
    Dep.clear!
  }
end
