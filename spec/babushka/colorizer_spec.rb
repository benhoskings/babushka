require 'spec_helper'

describe String::Colorizer do
  describe '.escape_for' do
    describe 'single settings' do
      it "should work for nothing" do
        String::Colorizer.escape_for('reset').should == "\e[0;0;0m"
        String::Colorizer.escape_for('none').should == "\e[0;0;0m"
      end
      it "should work for foreground colours" do
        String::Colorizer.escape_for('green').should == "\e[0;32;1m"
        String::Colorizer.escape_for('blue').should == "\e[0;34;1m"
        String::Colorizer.escape_for('grey').should == "\e[0;90;1m"
      end
      it "should work for background colours" do
        String::Colorizer.escape_for('on green').should == "\e[0;0;42m"
        String::Colorizer.escape_for('on blue').should == "\e[0;0;44m"
      end
      it "should work for control colours" do
        String::Colorizer.escape_for('underline').should == "\e[0;0;4m"
        String::Colorizer.escape_for('reverse').should == "\e[0;0;7m"
      end
    end
    describe 'combined settings' do
      it "should work for foreground + background" do
        String::Colorizer.escape_for('blue on green').should == "\e[0;34;42m"
      end
      it "should work for foreground + control" do
        String::Colorizer.escape_for('underlined green').should == "\e[0;32;4m"
      end
      it "should work for background + control (ignoring the control)" do
        String::Colorizer.escape_for('underlined on green').should == "\e[0;0;42m"
      end
      it "should work for foreground + background + control (ignoring the control)" do
        String::Colorizer.escape_for('underlined blue on green').should == "\e[0;34;42m"
      end
    end
  end
end
