require 'spec_helper'

describe Babushka::CurrentRuby do
  let(:current_ruby) { Babushka::CurrentRuby.new }
  before {
    allow(current_ruby).to receive(:gem_env).and_return(%{
RubyGems Environment:
  - RUBYGEMS VERSION: 1.8.23
  - INSTALLATION DIRECTORY: /usr/local/lib/ruby/gems/1.9.1
  - EXECUTABLE DIRECTORY: /usr/local/bin
      })
  }

  describe '#path' do
    it "should return the path to the ruby binary" do
      allow(Babushka::ShellHelpers).to receive(:which).with('ruby').and_return('/usr/local/bin/ruby')
      expect(current_ruby.path).to eq('/usr/local/bin/ruby')
    end
  end

  describe '#rbenv?' do
    it "should return true when ruby is running via rbenv" do
      allow(Babushka::ShellHelpers).to receive(:which).with('ruby').and_return('/Users/steve/.rbenv/shims/ruby')
      expect(current_ruby.rbenv?).to be_truthy
    end
    it "should return false otherwise" do
      allow(Babushka::ShellHelpers).to receive(:which).with('ruby').and_return('/usr/local/bin/ruby')
      expect(current_ruby.rbenv?).to be_falsey
    end
  end

  describe '#rvm?' do
    it "should return true when ruby is running via rvm" do
      allow(Babushka::ShellHelpers).to receive(:which).with('ruby').and_return('/Users/steve/.rvm/rubies/ruby-1.9.3-p194/bin/ruby')
      expect(current_ruby.rvm?).to be_truthy
    end
    it "should return false otherwise" do
      allow(Babushka::ShellHelpers).to receive(:which).with('ruby').and_return('/usr/local/bin/ruby')
      expect(current_ruby.rvm?).to be_falsey
    end
  end

  describe '#bin_dir' do
    it "should return the path containing the ruby binary" do
      expect(current_ruby.bin_dir).to eq('/usr/local/bin')
    end
  end

  describe '#gem_dir' do
    it "should return the directory containing installed gems" do
      expect(current_ruby.gem_dir).to eq('/usr/local/lib/ruby/gems/1.9.1/gems')
    end
  end

  describe '#gemspec_dir' do
    it "should return the directory containing installed gems' specs" do
      expect(current_ruby.gemspec_dir).to eq('/usr/local/lib/ruby/gems/1.9.1/specifications')
    end
  end

  describe '#version' do
    it "should return the version of the ruby installation" do
      allow(Babushka::ShellHelpers).to receive(:shell).with('ruby --version').and_return('ruby 1.9.3p194 (2012-04-20 revision 35410) [x86_64-linux]')
      expect(current_ruby.version).to eq(Babushka::VersionStr.new('1.9.3p194'))
    end
  end

  describe '#gem_version' do
    it "should return the version of the ruby installation's rubygems" do
      expect(current_ruby.gem_version).to eq(Babushka::VersionStr.new('1.8.23'))
    end
  end
end
