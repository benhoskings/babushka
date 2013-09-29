require 'spec_helper'

describe Babushka::ANSI do
  describe '.wrap' do
    before {
      Babushka::Base.cmdline.opts.stub(:[]).with(:"[no_]color") { true }
    }
    it "should wrap the input in ansi codes" do
      Babushka::ANSI.wrap('lol', 'blue').should == "\e[34mlol\e[m"
    end
  end
  describe '.escape_for' do
    describe 'single settings' do
      it "should work for nothing" do
        Babushka::ANSI.escape_for('reset').should == "\e[m"
        Babushka::ANSI.escape_for('none').should == "\e[m"
      end
      it "should work for foreground colours" do
        Babushka::ANSI.escape_for('green').should == "\e[32m"
        Babushka::ANSI.escape_for('blue').should == "\e[34m"
        Babushka::ANSI.escape_for('grey').should == "\e[90m"
      end
      it "should work for background colours" do
        Babushka::ANSI.escape_for('on green').should == "\e[42m"
        Babushka::ANSI.escape_for('on blue').should == "\e[44m"
        Babushka::ANSI.escape_for('on grey').should == "\e[100m"
      end
      it "should work for control colours" do
        Babushka::ANSI.escape_for('underline').should == "\e[4m"
        Babushka::ANSI.escape_for('reverse').should == "\e[7m"
      end
    end
    describe 'combined settings' do
      it "should work for foreground + background" do
        Babushka::ANSI.escape_for('blue on green').should == "\e[34;42m"
      end
      it "should work for foreground + control" do
        Babushka::ANSI.escape_for('underlined green').should == "\e[32;4m"
      end
      it "should work for background + control" do
        Babushka::ANSI.escape_for('underlined on green').should == "\e[42;4m"
      end
      it "should work for foreground + background + control" do
        Babushka::ANSI.escape_for('underlined blue on green').should == "\e[34;42;4m"
      end
    end
  end
end
