require 'spec_helper'

describe "help" do
  context "with no verb" do
    it "should print the verb help information" do
      Base.should_receive(:print_usage)
      Base.should_receive(:print_choices_for).with('commands', Base::Verbs)
      Base.should_receive(:print_notes)
      Base.run ['help']
    end
  end
  context "with a verb" do
    it "should print the help information for the verb" do
      verb = Base::Verbs.detect {|v| v.name == :meet }
      Base.should_receive(:print_usage_for).with(verb)
      Base.should_receive(:print_choices_for).with('options', verb.opts + verb.args)
      Base.run ['help', 'meet']
    end
  end
end
