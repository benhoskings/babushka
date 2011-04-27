require 'spec_helper'

describe Vars do
  before {
    Base.task.vars.define_var :username, :default => shell('whoami')
    Base.task.vars.define_var :domain, :default => :username
    Base.task.vars.define_var :db_name
    Base.task.vars.define_var :test_user, :default => :db_name
    Base.task.vars.set :nginx_version, '0.7.64'
  }
  describe "without values" do
    it "should return a direct value" do
      Base.task.vars.var(:nginx_version).should == '0.7.64'
    end
    it "should return a direct default" do
      Base.task.vars.default_for(:username).should == `whoami`.chomp
    end
    it "should return a referenced default" do
      Base.task.vars.default_for(:domain).should == `whoami`.chomp
    end
    it "should return nothing when no default is set" do
      Base.task.vars.default_for(:db_name).should be_nil
    end
    it "should return nothing when no default is set on the referred var" do
      Base.task.vars.default_for(:test_user).should be_nil
    end
  end
  describe "with values" do
    before {
      Base.task.vars.set :username, 'bob'
      Base.task.vars.set :db_name, 'bobs_database'
    }
    it "should return a direct value, overriding default" do
      Base.task.vars.var(:username).should == 'bob'
    end
    it "should return a referenced value as a default" do
      Base.task.vars.default_for(:domain).should == 'bob'
    end
    it "should return a direct value when there is no default" do
      Base.task.vars.var(:db_name).should == 'bobs_database'
    end
    it "should return a referenced value when there is no referenced default" do
      Base.task.vars.default_for(:test_user).should == 'bobs_database'
    end
  end
  describe "with values" do
    before {
      Base.task.vars.set :username, 'bob'
      Base.task.vars.set :db_name, 'bobs_database'
      Base.task.vars.set :test_user, 'senor_bob'
    }
    it "should return a direct value when there is no default" do
      Base.task.vars.var(:db_name).should == 'bobs_database'
    end
    it "should return a direct value, overriding the referenced default" do
      Base.task.vars.default_for(:test_user).should == 'bobs_database'
    end
  end
end
