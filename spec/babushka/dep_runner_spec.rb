require 'spec_helper'

describe "vars" do
  before {
    dep 'runner spec' do
      define_var :username, :default => shell('whoami')
      define_var :domain, :default => :username
      define_var :db_name
      define_var :test_user, :default => :db_name
      setup {
        set :nginx_version, '0.7.64'
      }
    end
  }
  describe "without values" do
    before {
      Dep('runner spec').met? # so setup{} is called
      @runner = Dep('runner spec').definer
    }
    it "should return a direct value" do
      @runner.var(:nginx_version).should == '0.7.64'
    end
    it "should return a direct default" do
      @runner.default_for(:username).should == `whoami`.chomp
    end
    it "should return a referenced default" do
      @runner.default_for(:domain).should == `whoami`.chomp
    end
    it "should return nothing when no default is set" do
      @runner.default_for(:db_name).should be_nil
    end
    it "should return nothing when no default is set on the referred var" do
      @runner.default_for(:test_user).should be_nil
    end
  end
  describe "with values" do
    before {
      Dep('runner spec').definer.setup {
        set :username, 'bob'
        set :db_name, 'bobs_database'
      }
      Dep('runner spec').met? # so setup{} is called
      @runner = Dep('runner spec').definer
    }
    it "should return a direct value, overriding default" do
      @runner.var(:username).should == 'bob'
    end
    it "should return a referenced value as a default" do
      @runner.default_for(:domain).should == 'bob'
    end
    it "should return a direct value when there is no default" do
      @runner.var(:db_name).should == 'bobs_database'
    end
    it "should return a referenced value when there is no referenced default" do
      @runner.default_for(:test_user).should == 'bobs_database'
    end
  end
  describe "with values" do
    before {
      Dep('runner spec').definer.setup {
        set :username, 'bob'
        set :db_name, 'bobs_database'
        set :test_user, 'senor_bob'
      }
      Dep('runner spec').met? # so setup{} is called
      @runner = Dep('runner spec').definer
    }
    it "should return a direct value when there is no default" do
      @runner.var(:db_name).should == 'bobs_database'
    end
    it "should return a direct value, overriding the referenced default" do
      @runner.default_for(:test_user).should == 'bobs_database'
    end
  end
end
