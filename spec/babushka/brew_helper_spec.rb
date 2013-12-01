require 'spec_helper'

describe Babushka::BrewHelper do
  let(:brew_helper) { Babushka::BrewHelper }
  describe '#active_version_of' do
    context "when a version is active" do
      before {
        brew_helper.stub(:version_info_for).with('readline').and_return(
          [['6.2.1', false], ['6.2.2', true], ['6.2.4', false]]
        )
      }
      it "should return the active version" do
        brew_helper.send(:active_version_of, 'readline').should == '6.2.2'
      end
    end
    context "when no version is active" do
      before {
        brew_helper.stub(:version_info_for).with('readline').and_return(
          [['6.2.1', false], ['6.2.2', false], ['6.2.4', false]]
        )
      }
      it "should be nil" do
        brew_helper.send(:active_version_of, 'readline').should be_nil
      end
    end
  end

  describe '#versions_of' do
    before {
      brew_helper.stub(:version_info_for).with('readline').and_return(
        [['6.2.1', false], ['6.2.2', true], ['6.2.4', false]]
      )
    }
    it "should return the installed versions" do
      brew_helper.send(:versions_of, 'readline').should == ['6.2.1', '6.2.2', '6.2.4']
    end
  end

  describe '#version_info_for' do
    before {
      brew_helper.stub(:prefix).and_return('/usr/local') # For systems that don't have `brew` in the path
      Babushka::ShellHelpers.stub(:shell).with('brew info readline').and_return("readline: stable 6.2.4
http://tiswww.case.edu/php/chet/readline/rltop.html

This formula is keg-only.
OS X provides the BSD libedit library, which shadows libreadline.
In order to prevent conflicts when programs look for libreadline we are
defaulting this GNU Readline installation to keg-only.

/usr/local/Cellar/readline/6.2.1 (28 files, 1.6M)
Built from source
/usr/local/Cellar/readline/6.2.2 (30 files, 1.7M) *
/usr/local/Cellar/readline/not_a_version (30 files, 1.7M)
/usr/local/Cellar/readline/6.2.4 (30 files, 1.0M)
From: https://github.com/mxcl/homebrew/commits/master/Library/Formula/readline.rb")
    }
    it "should return the installed versions, excluding non-versions and marking the active version" do
      brew_helper.send(:version_info_for, 'readline').should == [
        ['6.2.1', false],
        ['6.2.2', true],
        ['6.2.4', false]
      ]
    end
  end

  describe '#has_formula_for?' do
    before {
      brew_helper.stub(:prefix).and_return('/usr/local')
      Dir.stub(:[]).with('/usr/local/Library/Formula/*.rb', '/usr/local/Library/Taps/**/*.rb').and_return([
        '/usr/local/Library/Formula/zsh.rb',
        '/usr/local/Library/Taps/homebrew-dupes/apple-gcc42.rb',
        '/usr/local/Library/Taps/original-dev/Formula/redis.rb',
      ])
    }
    it "should find both core and tapped packages" do
      zsh = double('pkg', :name => 'zsh')
      gcc42 = double('pkg', :name => 'homebrew/dupes/apple-gcc42')
      redis = double('pkg', :name => 'original/dev/redis')

      brew_helper.send(:has_formula_for?, zsh).should be_true
      brew_helper.send(:has_formula_for?, gcc42).should be_true
      brew_helper.send(:has_formula_for?, redis).should be_true
    end
  end
end
