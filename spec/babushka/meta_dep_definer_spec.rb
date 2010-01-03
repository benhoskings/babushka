require 'spec_support'
require 'dep_definer_support'

describe "declaration" do
  before {
    @meta = meta 'test'
  }
  it "should define a dep definer" do
    @meta.definer_class.should be_an_instance_of Class
    @meta.definer_class.ancestors.should include Babushka::BaseDepDefiner
  end
  it "should define a dep runner" do
    @meta.runner_class.should be_an_instance_of Class
    @meta.runner_class.ancestors.should include Babushka::BaseDepRunner
  end
end
