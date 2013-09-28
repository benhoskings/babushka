require 'spec_helper'

describe String::Colorizer do
  describe '.colorize' do
    it "should wrap the input in ansi codes" do
      String::Colorizer.colorize('lol', 'blue').should == "\e[34mlol\e[m"
    end
  end
  describe '.escape_for' do
    describe 'single settings' do
      it "should work for nothing" do
        String::Colorizer.escape_for('reset').should == "\e[m"
        String::Colorizer.escape_for('none').should == "\e[m"
      end
      it "should work for foreground colours" do
        String::Colorizer.escape_for('green').should == "\e[32m"
        String::Colorizer.escape_for('blue').should == "\e[34m"
        String::Colorizer.escape_for('grey').should == "\e[90m"
      end
      it "should work for background colours" do
        String::Colorizer.escape_for('on green').should == "\e[42m"
        String::Colorizer.escape_for('on blue').should == "\e[44m"
        String::Colorizer.escape_for('on grey').should == "\e[100m"
      end
      it "should work for control colours" do
        String::Colorizer.escape_for('underline').should == "\e[4m"
        String::Colorizer.escape_for('reverse').should == "\e[7m"
      end
    end
    describe 'combined settings' do
      it "should work for foreground + background" do
        String::Colorizer.escape_for('blue on green').should == "\e[34;42m"
      end
      it "should work for foreground + control" do
        String::Colorizer.escape_for('underlined green').should == "\e[32;4m"
      end
      it "should work for background + control" do
        String::Colorizer.escape_for('underlined on green').should == "\e[42;4m"
      end
      it "should work for foreground + background + control" do
        String::Colorizer.escape_for('underlined blue on green').should == "\e[34;42;4m"
      end
    end
  end
end
