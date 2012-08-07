require 'spec_helper'

describe PathChecker do
  describe '.match_potential_versions' do
    it "should extract a single version" do
      PathChecker.match_potential_versions('0.13.2').should == ['0.13.2']
    end
    it "should extract multiple versions" do
      PathChecker.match_potential_versions('0.13.2 9.1.3').should == ['0.13.2', '9.1.3']
    end
    it "should extract a version with a 'v' prefix" do
      PathChecker.match_potential_versions('app v0.1.2').should == ['v0.1.2']
    end
    it "should work for babushka" do
      PathChecker.match_potential_versions('0.13.2 (f177e22)').should == ['0.13.2']
    end
    it "should work for postgres" do
      PathChecker.match_potential_versions('psql (PostgreSQL) 9.1.3
contains support for command-line editing').should == ['9.1.3']
    end
  end
end
