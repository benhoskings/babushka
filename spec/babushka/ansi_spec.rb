require 'spec_helper'

describe Babushka::ANSI do
  describe '.wrap' do
    before {
      allow(Babushka::Base.cmdline.opts).to receive(:[]).with(:"[no_]color") { true }
    }
    it "should wrap the input in ansi codes" do
      expect(Babushka::ANSI.wrap('lol', 'blue')).to eq("\e[34mlol\e[m")
    end
  end
  describe '.escape_for' do
    describe 'single settings' do
      it "should work for nothing" do
        expect(Babushka::ANSI.escape_for('reset')).to eq("\e[m")
        expect(Babushka::ANSI.escape_for('none')).to eq("\e[m")
      end
      it "should work for foreground colours" do
        expect(Babushka::ANSI.escape_for('green')).to eq("\e[32m")
        expect(Babushka::ANSI.escape_for('blue')).to eq("\e[34m")
      end
      context "on a linux pty" do
        before {
          allow(Babushka::ANSI).to receive(:linux_pty?) { true }
        }
        it "should use 'bold black' for grey" do
          expect(Babushka::ANSI.escape_for('grey')).to eq("\e[30;1m")
        end
      end
      context "on other terminals" do
        before {
          allow(Babushka::ANSI).to receive(:linux_pty?) { false }
        }
        it "should use 'bright black' for grey" do
          expect(Babushka::ANSI.escape_for('grey')).to eq("\e[90m")
        end
      end
      it "should work for background colours" do
        expect(Babushka::ANSI.escape_for('on green')).to eq("\e[42m")
        expect(Babushka::ANSI.escape_for('on blue')).to eq("\e[44m")
        expect(Babushka::ANSI.escape_for('on grey')).to eq("\e[100m")
      end
      it "should work for control colours" do
        expect(Babushka::ANSI.escape_for('underline')).to eq("\e[4m")
        expect(Babushka::ANSI.escape_for('reverse')).to eq("\e[7m")
      end
    end
    describe 'combined settings' do
      it "should work for foreground + background" do
        expect(Babushka::ANSI.escape_for('blue on green')).to eq("\e[34;42m")
      end
      it "should work for foreground + control" do
        expect(Babushka::ANSI.escape_for('underlined green')).to eq("\e[32;4m")
      end
      it "should work for background + control" do
        expect(Babushka::ANSI.escape_for('underlined on green')).to eq("\e[42;4m")
      end
      it "should work for foreground + background + control" do
        expect(Babushka::ANSI.escape_for('underlined blue on green')).to eq("\e[34;42;4m")
      end
    end
  end
end
