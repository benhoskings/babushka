require 'spec_helper'

describe Babushka::PathChecker do
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
      PathChecker.match_potential_versions('0.13.2 (f177e22)').should == ['0.13.2', 'f177e22']
    end
    it "should work for postgres" do
      PathChecker.match_potential_versions('psql (PostgreSQL) 9.1.3
contains support for command-line editing').should == ['9.1.3']
    end
    it "should match lots of things for ruby" do
      PathChecker.match_potential_versions(
        'ruby 1.9.3p194 (2012-04-20 revision 35410) [x86_64-darwin12.0.0]'
      ).should == ['1.9.3p194', '2012-04-20', '35410', 'x86_64-darwin12.0.0']
    end

    context "when a dotted version is supplied" do
      it "should only match against dotted potential versions" do
        PathChecker.match_potential_versions(
          'ruby 1.9.3p194 (2012-04-20 revision 35410) [x86_64-darwin12.0.0]', '1.9.3p0'
        ).should == ['1.9.3p194', 'x86_64-darwin12.0.0']
      end
    end
  end
end
