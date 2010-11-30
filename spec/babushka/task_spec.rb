require 'spec_helper'
require 'source_support'

standard_vars = {
  "rails_root" => {:default => "~/current", :value => "~/projects/corkboard/current"},
  "extra_domains" => {:default => "", :value => ""},
  "username" => {:default => "ben"},
  "versions" => {:value => {:nginx => "0.7.61", :upload_module => "2.0.9"}},
  "vhost_type" => {:default => "passenger", :value => "passenger"}
}

describe Task, "process" do
  describe "with a dep name" do
    before {
      dep 'task spec'
      Dep('task spec').should_receive(:process)
    }
    it "should run a dep when just the name is passed" do
      Base.task.process ['task spec']
    end
  end
  after {
    Base.task.saved_vars.clear
  }
end

describe Task, "vars_for_save" do
  before {
    Base.task.stub!(:vars).and_return(standard_vars)
    @vars_for_save = Base.task.send :vars_for_save
  }
  it "should create a saved_var for every var" do
    (Base.task.vars.keys - @vars_for_save.keys).should == []
  end
  describe "rejecting invalid input" do
    before {
      Base.task.stub!(:vars).and_return(standard_vars.merge({
        "www_aliases" => {:default => L{ 'stub' }, :value => "www.test3.org"},
        "db_password" => {:value => 'sekret'}
      }))
      @vars_for_save = Base.task.send :vars_for_save
    }
    it "should exclude invalid data types" do
      @vars_for_save['www_aliases'].has_key?(:default).should be_false
    end
    it "should reject passwords" do
      @vars_for_save.has_key?('db_password').should be_false
    end
  end
  describe "subsequent saves" do
    before {
      Base.task.stub!(:saved_vars).and_return(standard_vars)
      Base.task.stub!(:vars).and_return(standard_vars.reject {|k,v| %w[username versions vhost_type].include? k })
      @new_vars_for_save = Base.task.send :vars_for_save
    }
    it "should preserve old values" do
      (@vars_for_save.keys - @new_vars_for_save.keys).should == []
    end
  end
  describe "referred values" do
    before {
      Base.task.stub!(:vars).and_return(standard_vars.merge({
        "domain" => {:default => :username, :value => "test3.org"},
        "db_domain" => {:default => :domain},
        "db_name" => {:default => :username, :value => 'corkboard'},
        "db_user" => {:default => :db_name, :value => 'corkboard_user'},
        "app_name" => {:default => :username},
        "rake_root" => {:default => :rails_root},
        "static_root" => {:default => :rails_root, :value => "~/projects/corkboard/current/static"}
      }))
      @vars_for_save = Base.task.send :vars_for_save
    }
    it "should create saved_vars" do
      %w[domain db_name db_user rake_root static_root].each {|key|
        @vars_for_save.has_key?(key).should be_true
      }
    end
    it "should not create a :value" do
      %w[domain db_name db_user rake_root static_root].each {|key|
        @vars_for_save[key].has_key?(:value).should be_false
      }
    end
    it "should store the referenced var's value in :values" do
      @vars_for_save['domain'][:values].should == {nil => 'test3.org'}
      @vars_for_save['db_domain'][:values].should == {}
      @vars_for_save['db_name'][:values].should == {nil => 'corkboard'}
      @vars_for_save['db_user'][:values].should == {'corkboard' => 'corkboard_user'}
      @vars_for_save['app_name'][:values].should == {}
      @vars_for_save['rake_root'][:values].should == {}
      @vars_for_save['static_root'][:values].should == {'~/projects/corkboard/current' => '~/projects/corkboard/current/static'}
    end
  end
end
