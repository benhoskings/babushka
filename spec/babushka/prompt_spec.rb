require 'spec_helper'

RSpec.describe Babushka::Prompt, "get_value" do
  it "should raise when not running on a terminal" do
    expect(STDIN).to receive(:tty?).and_return(false)
    expect { Babushka::Prompt.get_value('value') }.to raise_error(Babushka::PromptUnavailable)
  end

  it "should raise when not running on a terminal and a default is present" do
    expect(STDIN).to receive(:tty?).and_return(false)
    expect { Babushka::Prompt.get_value('value', :default => 'a default') }.to raise_error(Babushka::PromptUnavailable)
  end

  it "should raise when a default is expected but not available" do
    expect(Babushka::Base.task).to receive(:opt).with(:defaults).and_return(true)
    expect { Babushka::Prompt.get_value('value') }.to raise_error(Babushka::DefaultUnavailable)
  end

  it "should return the value" do
    expect(STDIN).to receive(:tty?).and_return(true)
    expect(Babushka::LogHelpers).to receive(:log).with("value", {:newline => false})
    expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('value')
    expect(Babushka::Prompt.get_value('value')).to eq('value')
  end

  describe "with default" do
    it "should return the value when it's specified" do
      expect(STDIN).to receive(:tty?).and_return(true)
      expect(Babushka::LogHelpers).to receive(:log).with("value [default]", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('value')
      expect(Babushka::Prompt.get_value('value', :default => 'default')).to eq('value')
    end
    it "should return the default when no value is specified" do
      expect(STDIN).to receive(:tty?).and_return(true)
      expect(Babushka::LogHelpers).to receive(:log).with("value [default]", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('')
      expect(Babushka::Prompt.get_value('value', :default => 'default')).to eq('default')
    end
    it "should handle non-string defaults" do
      expect(STDIN).to receive(:tty?).and_return(true)
      expect(Babushka::LogHelpers).to receive(:log).with("value [80]", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('')
      expect(Babushka::Prompt.get_value('value', :default => 80)).to eq('80')
    end
  end

  it "should reject :choices and :choice_descriptions together" do
    expect(L{
      Babushka::Prompt.get_value('value', :choices => %w[a b c], :choice_descriptions => {:a => "description"})
    }).to raise_error(ArgumentError, "You can't use the :choices and :choice_descriptions options together.")
  end

  describe "with choices" do
    it "should accept a valid choice" do
      expect(STDIN).to receive(:tty?).and_return(true)
      expect(Babushka::LogHelpers).to receive(:log).with("value (a,b,c)", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('a')
      expect(Babushka::Prompt.get_value('value', :choices => %w[a b c])).to eq('a')
    end
    it "should reject an invalid choice" do
      expect(STDIN).to receive(:tty?).and_return(true)
      expect(Babushka::LogHelpers).to receive(:log).with("value (a,b,c)", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('d')
      expect(Babushka::LogHelpers).to receive(:log).with("That's not a valid choice. value (a,b,c)", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('a')
      expect(Babushka::Prompt.get_value('value', :choices => %w[a b c])).to eq('a')
    end
    it "should reject non-string choices" do
      expect(L{
        Babushka::Prompt.get_value('value', :choices => [:a, :b])
      }).to raise_error ArgumentError, "Choices must be passed as strings."
    end
    describe "with default" do
      it "should accept a valid choice" do
        expect(STDIN).to receive(:tty?).and_return(true)
        expect(Babushka::LogHelpers).to receive(:log).with("value (a,b,c) [b]", {:newline => false})
        expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('a')
        expect(Babushka::Prompt.get_value('value', :choices => %w[a b c], :default => 'b')).to eq('a')
      end
      it "should reject an invalid choice" do
        expect(STDIN).to receive(:tty?).and_return(true)
        expect(Babushka::LogHelpers).to receive(:log).with("value (a,b,c) [b]", {:newline => false})
        expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('d')
        expect(Babushka::LogHelpers).to receive(:log).with("That's not a valid choice. value (a,b,c) [b]", {:newline => false})
        expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('a')
        expect(Babushka::Prompt.get_value('value', :choices => %w[a b c], :default => 'b')).to eq('a')
      end
      describe "with no value specified" do
        it "should accept a valid default" do
          expect(STDIN).to receive(:tty?).and_return(true)
          expect(Babushka::LogHelpers).to receive(:log).with("value (a,b,c) [b]", {:newline => false})
          expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('')
          expect(Babushka::Prompt.get_value('value', :choices => %w[a b c], :default => 'b')).to eq('b')
        end
        it "should reject an invalid default" do
          expect(STDIN).to receive(:tty?).and_return(true)
          expect(Babushka::LogHelpers).to receive(:log).with("value (a,b,c) [d]", {:newline => false})
          expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('')
          expect(Babushka::LogHelpers).to receive(:log).with("That's not a valid choice. value (a,b,c) [d]", {:newline => false})
          expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('a')
          expect(Babushka::Prompt.get_value('value', :choices => %w[a b c], :default => 'd')).to eq('a')
        end
      end
    end
  end

  describe "with choice descriptions" do
    it "should behave like choices, logging the descriptions" do
      expect(STDIN).to receive(:tty?).and_return(true)
      expect(Babushka::LogHelpers).to receive(:log).with("There are 3 choices:")
      expect(Babushka::LogHelpers).to receive(:log).with("a - the first one")
      expect(Babushka::LogHelpers).to receive(:log).with("b - there's also this")
      expect(Babushka::LogHelpers).to receive(:log).with("c - or this")
      expect(Babushka::LogHelpers).to receive(:log).with("value", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('d')
      expect(Babushka::LogHelpers).to receive(:log).with("That's not a valid choice. value", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('a')
      expect(Babushka::Prompt.get_value('value', :choice_descriptions => {'a' => "the first one", 'b' => "there's also this", 'c' => "or this"})).to eq('a')
    end
  end

  describe "validation" do
    it "should treat 'true' as valid" do
      expect(STDIN).to receive(:tty?).and_return(true)
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('value')
      expect(Babushka::Prompt.get_value('value') {|value| true }).to eq('value')
    end
    it "should treat 'false' as invalid" do
      expect(STDIN).to receive(:tty?).and_return(true)
      expect(Babushka::LogHelpers).to receive(:log).with("value", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('another value')
      expect(Babushka::LogHelpers).to receive(:log).with("That wasn't valid. value", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('value')
      expect(Babushka::Prompt.get_value('value') {|value| value == 'value' }).to eq('value')
    end
  end
end

RSpec.describe "'y' input" do
  context "intentional" do
    it "should return 'y'" do
      expect(STDIN).to receive(:tty?).twice.and_return(true)
      expect(Babushka::LogHelpers).to receive(:log).with("value", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('y')
      expect(Babushka::LogHelpers).to receive(:log).with("Wait, do you mean the literal value 'y' [n]", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('y')
      expect(Babushka::Prompt.get_value('value')).to eq('y')
    end
  end
  context "unintentional" do
    it "should ask for the value again with a custom log message" do
      # The #tty? call is in #prompt_and_read_value, which isn't re-called
      # in the "Thought so :)" case, hence only 2 calls.
      expect(STDIN).to receive(:tty?).twice.and_return(true)
      expect(Babushka::LogHelpers).to receive(:log).with("value", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('yes')
      expect(Babushka::LogHelpers).to receive(:log).with("Wait, do you mean the literal value 'yes' [n]", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('n')
      expect(Babushka::LogHelpers).to receive(:log).with("Thought so :) Hit enter for the [default]. value", {:newline => false})
      expect(Babushka::Prompt).to receive(:read_from_prompt).and_return('value')
      expect(Babushka::Prompt.get_value('value')).to eq('value')
    end
  end
end
