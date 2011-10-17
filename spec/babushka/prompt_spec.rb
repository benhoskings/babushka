require 'spec_helper'

describe Prompt, "get_value" do
  it "should raise when not running on a terminal" do
    $stdin.should_receive(:tty?).and_return(false)
    expect { Prompt.get_value('value') }.to raise_error(PromptUnavailable)
  end

  it "should raise when a default is expected but not available" do
    Base.task.should_receive(:opt).with(:defaults).and_return(true)
    expect { Prompt.get_value('value') }.to raise_error(DefaultUnavailable)
  end

  it "should return the value" do
    Prompt.should_receive(:log).with("value", {:newline => false})
    Prompt.should_receive(:read_from_prompt).and_return('value')
    Prompt.get_value('value').should == 'value'
  end

  describe "with default" do
    it "should return the value when it's specified" do
      Prompt.should_receive(:log).with("value [default]", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('value')
      Prompt.get_value('value', :default => 'default').should == 'value'
    end
    it "should return the default when no value is specified" do
      Prompt.should_receive(:log).with("value [default]", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('')
      Prompt.get_value('value', :default => 'default').should == 'default'
    end
    it "should handle non-string defaults" do
      Prompt.should_receive(:log).with("value [80]", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('')
      Prompt.get_value('value', :default => 80).should == '80'
    end
  end

  it "should reject :choices and :choice_descriptions together" do
    L{
      Prompt.get_value('value', :choices => %w[a b c], :choice_descriptions => {:a => "description"})
    }.should raise_error(ArgumentError, "You can't use the :choices and :choice_descriptions options together.")
  end

  describe "with choices" do
    it "should accept a valid choice" do
      Prompt.should_receive(:log).with("value (a,b,c)", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('a')
      Prompt.get_value('value', :choices => %w[a b c]).should == 'a'
    end
    it "should reject an invalid choice" do
      Prompt.should_receive(:log).with("value (a,b,c)", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('d')
      Prompt.should_receive(:log).with("That's not a valid choice. value (a,b,c)", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('a')
      Prompt.get_value('value', :choices => %w[a b c]).should == 'a'
    end
    it "should reject non-string choices" do
      L{
        Prompt.get_value('value', :choices => [:a, :b])
      }.should raise_error ArgumentError, "Choices must be passed as strings."
    end
    describe "with default" do
      it "should accept a valid choice" do
        Prompt.should_receive(:log).with("value (a,b,c) [b]", {:newline => false})
        Prompt.should_receive(:read_from_prompt).and_return('a')
        Prompt.get_value('value', :choices => %w[a b c], :default => 'b').should == 'a'
      end
      it "should reject an invalid choice" do
        Prompt.should_receive(:log).with("value (a,b,c) [b]", {:newline => false})
        Prompt.should_receive(:read_from_prompt).and_return('d')
        Prompt.should_receive(:log).with("That's not a valid choice. value (a,b,c) [b]", {:newline => false})
        Prompt.should_receive(:read_from_prompt).and_return('a')
        Prompt.get_value('value', :choices => %w[a b c], :default => 'b').should == 'a'
      end
      describe "with no value specified" do
        it "should accept a valid default" do
          Prompt.should_receive(:log).with("value (a,b,c) [b]", {:newline => false})
          Prompt.should_receive(:read_from_prompt).and_return('')
          Prompt.get_value('value', :choices => %w[a b c], :default => 'b').should == 'b'
        end
        it "should reject an invalid default" do
          Prompt.should_receive(:log).with("value (a,b,c) [d]", {:newline => false})
          Prompt.should_receive(:read_from_prompt).and_return('')
          Prompt.should_receive(:log).with("That's not a valid choice. value (a,b,c) [d]", {:newline => false})
          Prompt.should_receive(:read_from_prompt).and_return('a')
          Prompt.get_value('value', :choices => %w[a b c], :default => 'd').should == 'a'
        end
      end
    end
  end

  describe "with choice descriptions" do
    it "should behave like choices, logging the descriptions" do
      Prompt.should_receive(:log).with("There are 3 choices:")
      Prompt.should_receive(:log).with("a - the first one")
      Prompt.should_receive(:log).with("b - there's also this")
      Prompt.should_receive(:log).with("c - or this")
      Prompt.should_receive(:log).with("value", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('d')
      Prompt.should_receive(:log).with("That's not a valid choice. value", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('a')
      Prompt.get_value('value', :choice_descriptions => {'a' => "the first one", 'b' => "there's also this", 'c' => "or this"}).should == 'a'
    end
  end

  describe "validation" do
    it "should treat 'true' as valid" do
      Prompt.should_receive(:read_from_prompt).and_return('value')
      Prompt.get_value('value') {|value| true }.should == 'value'
    end
    it "should treat 'false' as invalid" do
      Prompt.should_receive(:log).with("value", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('another value')
      Prompt.should_receive(:log).with("That wasn't valid. value", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('value')
      Prompt.get_value('value') {|value| value == 'value' }.should == 'value'
    end
  end
end

describe Prompt, "#get_path" do
  it "should return the path" do
    Prompt.should_receive(:log).with("path", {:newline => false})
    Prompt.should_receive(:read_from_prompt).and_return(tmp_prefix)
    Prompt.get_path('path', :type => :path).should == tmp_prefix
  end
  it "should return ~ intact" do
    Prompt.should_receive(:log).with("path", {:newline => false})
    Prompt.should_receive(:read_from_prompt).and_return('~')
    Prompt.get_path('path').should == '~'
  end
  describe "with default" do
    it "should return the value when it's specified" do
      Prompt.should_receive(:log).with("path [/tmp]", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return(tmp_prefix)
      Prompt.get_path('path', :default => '/tmp').should == tmp_prefix
    end
    it "should return the default when no value is specified" do
      Prompt.should_receive(:log).with("path [/tmp]", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('')
      Prompt.get_path('path', :default => '/tmp').should == '/tmp'
    end
  end
  describe "with nonexistent path" do
    it "should fail" do
      Prompt.should_receive(:log).with("path", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return((tmp_prefix / 'nonexistent').to_s)
      Prompt.should_receive(:log).with("Doesn't exist, or not a directory. path", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return(tmp_prefix)
      Prompt.get_path('path', :type => :path).should == tmp_prefix
    end
    it "should fail with a valid default" do
      Prompt.should_receive(:log).with("path [/tmp]", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return((tmp_prefix / 'nonexistent').to_s)
      Prompt.should_receive(:log).with("Doesn't exist, or not a directory. path [/tmp]", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return(tmp_prefix)
      Prompt.get_path('path', :type => :path, :default => '/tmp').should == tmp_prefix
    end
  end
end

describe "'y' input" do
  context "intentional" do
    it "should return 'y'" do
      Prompt.should_receive(:log).with("value", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('y')
      Prompt.should_receive(:log).with("Wait, do you mean the literal value 'y' [n]", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('y')
      Prompt.get_value('value').should == 'y'
    end
  end
  context "unintentional" do
    it "should ask for the value again with a custom log message" do
      Prompt.should_receive(:log).with("value", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('y')
      Prompt.should_receive(:log).with("Wait, do you mean the literal value 'y' [n]", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('n')
      Prompt.should_receive(:log).with("Thought so :) Hit enter for the [default]. value", {:newline => false})
      Prompt.should_receive(:read_from_prompt).and_return('value')
      Prompt.get_value('value').should == 'value'
    end
  end
end
