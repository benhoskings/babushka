require 'spec_support'
require 'prompt_helpers_support'

describe "prompt_for_value" do
  it "should return the value" do
    @values = ['value']
    prompt_for_value('value').should == 'value'
  end

  describe "with default" do
    it "should return the value when it's specified" do
      @values = ['value']
      prompt_for_value('value', :default => 'default').should == 'value'
    end
    it "should return the default when no value is specified" do
      @values = ['']
      prompt_for_value('value', :default => 'default').should == 'default'
    end
  end

  describe "with choices" do
    it "should accept a valid choice" do
      @values = ['a']
      prompt_for_value('value', :choices => %w[a b c]).should == 'a'
    end
    it "should reject an invalid choice" do
      @values = ['d']
      prompt_for_value('value', :choices => %w[a b c]).should == nil
    end
    describe "with default" do
      it "should accept a valid choice" do
        @values = ['a']
        prompt_for_value('value', :choices => %w[a b c], :default => 'b').should == 'a'
      end
      it "should reject an invalid choice" do
        @values = ['d'] * 10
        prompt_for_value('value', :choices => %w[a b c], :default => 'b').should == nil
      end
      describe "with no value specified" do
        before { @values = [''] }
        it "should accept a valid default" do
          prompt_for_value('value', :choices => %w[a b c], :default => 'b').should == 'b'
        end
        it "should reject an invalid default" do
          prompt_for_value('value', :choices => %w[a b c], :default => 'd').should == nil
        end
      end
    end
  end
end

describe "prompt_for_path" do
  before { @values = [tmp_prefix] }
  it "should return the path" do
    prompt_for_path('path', :type => :path).should == tmp_prefix
  end
  describe "with ~" do
    before { @values = ['~'] }
    it "should return the path" do
      prompt_for_path('path').should == '~'
    end
  end
  describe "with default" do
    it "should return the value when it's specified" do
      @values = [tmp_prefix]
      prompt_for_path('path', :default => '/tmp').should == tmp_prefix
    end
    it "should return the default when no value is specified" do
      @values = ['']
      prompt_for_path('path', :default => '/tmp').should == '/tmp'
    end
  end
  describe "with nonexistent path" do
    before { @values = [tmp_prefix / 'nonexistent_path'] * 10 }
    it "should fail" do
      prompt_for_path('path', :type => :path).should be_nil
    end
    it "should fail with a valid default" do
      prompt_for_path('path', :type => :path, :default => '/tmp').should be_nil
    end
  end
end

describe "'y' input" do
  context "intentional" do
    before { @values = ['y', 'y'] }
    it "should return 'y'" do
      prompt_for_value('value').should == 'y'
    end
  end
  context "unintentional" do
    before { @values = ['y', 'n', ''] }
    it "should return nil" do
      prompt_for_value('value').should == nil
    end
    context "with default" do
      before { @values = ['y', 'n', ''] }
      it "should return the value" do
        prompt_for_value('value', :default => 'val').should == 'val'
      end
    end
    context "repeated" do
      before { @values = ['y', 'n', 'y', 'n', ''] }
      it "should return nil" do
        prompt_for_value('value').should == nil
      end
      context "with default" do
        before { @values = ['y', 'n', 'y', 'n', ''] }
        it "should return the value" do
          prompt_for_value('value', :default => 'val').should == 'val'
        end
      end
    end
  end
end
