require 'spec_helper'

describe Babushka::CurrentRuby do
  let(:current_ruby) { Babushka::CurrentRuby.new }
  before {
    current_ruby.stub!(:gem_env).and_return(%{
RubyGems Environment:
  - RUBYGEMS VERSION: 1.8.23
  - INSTALLATION DIRECTORY: /usr/local/lib/ruby/gems/1.9.1
  - EXECUTABLE DIRECTORY: /usr/local/bin
      })
  }

  describe '#path' do
    it "should return the path to the ruby binary" do
      Babushka::ShellHelpers.stub!(:which).with('ruby').and_return('/usr/local/bin/ruby')
      current_ruby.path.should == '/usr/local/bin/ruby'
    end
  end

  describe '#bin_dir' do
    it "should return the path containing the ruby binary" do
      current_ruby.bin_dir.should == '/usr/local/bin'
    end
  end

  describe '#gem_dir' do
    it "should return the directory containing installed gems" do
      current_ruby.gem_dir.should == '/usr/local/lib/ruby/gems/1.9.1/gems'
    end
  end

  describe '#gemspec_dir' do
    it "should return the directory containing installed gems' specs" do
      current_ruby.gemspec_dir.should == '/usr/local/lib/ruby/gems/1.9.1/specifications'
    end
  end

  describe '#version' do
    it "should return the version of the ruby installation" do
      Babushka::ShellHelpers.stub!(:shell).with('ruby --version').and_return('ruby 1.9.3p194 (2012-04-20 revision 35410) [x86_64-linux]')
      current_ruby.version.should == Babushka::VersionStr.new('1.9.3p194')
    end
  end

  describe '#gem_version' do
    it "should return the version of the ruby installation's rubygems" do
      current_ruby.gem_version.should == Babushka::VersionStr.new('1.8.23')
    end
  end
end
