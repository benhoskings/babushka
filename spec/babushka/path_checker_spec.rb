require 'spec_helper'

describe Babushka::PathChecker do
  describe '.cmds_in_path?' do
    context 'when the commands run from multiple paths' do
      let(:klass) { Struct.new(:name) }
      let(:commands) { %w(hi bye sup).map { |n| klass.new(n) } }
      before { Babushka::PathChecker.stub(:cmd_dir) { |c| c } }

      context 'when answering yes at the prompt' do
        before { Babushka::Prompt.stub(:confirm).and_return(true) }

        it 'should proceed when answering yes at the prompt' do
          expect { Babushka::PathChecker.cmds_in_path?(commands).should be true }.not_to raise_error
        end
      end
    end
  end

  describe '.match_potential_versions' do
    it "should extract a single version" do
      Babushka::PathChecker.match_potential_versions('0.13.2').should == ['0.13.2']
    end
    it "should extract multiple versions" do
      Babushka::PathChecker.match_potential_versions('0.13.2 9.1.3').should == ['0.13.2', '9.1.3']
    end
    it "should extract a version with a 'v' prefix" do
      Babushka::PathChecker.match_potential_versions('app v0.1.2').should == ['v0.1.2']
    end
    it "should work for babushka" do
      Babushka::PathChecker.match_potential_versions('0.13.2 (f177e22)').should == ['0.13.2', 'f177e22']
    end
    it "should work for postgres" do
      Babushka::PathChecker.match_potential_versions('psql (PostgreSQL) 9.1.3
contains support for command-line editing').should == ['9.1.3']
    end
    it "should match lots of things for ruby" do
      Babushka::PathChecker.match_potential_versions(
        'ruby 1.9.3p194 (2012-04-20 revision 35410) [x86_64-darwin12.0.0]'
      ).should == ['1.9.3p194', '2012-04-20', '35410', 'x86_64-darwin12.0.0']
    end

    context "when a dotted version is supplied" do
      it "should only match against dotted potential versions" do
        Babushka::PathChecker.match_potential_versions(
          'ruby 1.9.3p194 (2012-04-20 revision 35410) [x86_64-darwin12.0.0]', '1.9.3p0'
        ).should == ['1.9.3p194', 'x86_64-darwin12.0.0']
      end
    end
  end
end
