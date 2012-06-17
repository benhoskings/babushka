require 'spec_helper'


describe "lambda choosing" do
  it "should return the value of the block when there are no choices" do
    LambdaChooser.new(nil, :ours, :theirs) {
      "block value"
    }.choose(:ours, :on).should == "block value"
  end

  it "should choose the specified call" do
    LambdaChooser.new(nil, :ours, :theirs) {
      on :ours, "this is ours"
      on :theirs, "this is theirs"
      "block value should be ignored"
    }.choose(:ours, :on).should == ["this is ours"]
  end

  it "should pick the first choice from multiple choices" do
    LambdaChooser.new(nil, :ours, :yours, :theirs) {
      on :ours, "this is ours"
      on :yours, "this is yours"
      on :theirs, "this is theirs"
    }.choose([:ours, :yours], :on).should == ["this is ours"]
    LambdaChooser.new(nil, :ours, :yours, :theirs) {
      on :yours, "this is yours"
      on :ours, "this is ours"
      on :theirs, "this is theirs"
    }.choose([:ours, :yours], :on).should == ["this is ours"]
  end

  context "with multiple targets" do
    it "should choose the specified call" do
      LambdaChooser.new(nil, :ours, :theirs, :yours) {
        on :ours, "this is ours"
        on [:theirs, :yours], "this is theirs or yours"
        "block value should be ignored"
      }.choose(:yours, :on).should == ["this is theirs or yours"]
    end
    it "should pick the first choice from multiple choices" do
      LambdaChooser.new(nil, :ours, :yours, :theirs) {
        on :ours, "this is ours"
        on [:theirs, :yours], "this is theirs or yours"
      }.choose([:ours, :yours], :on).should == ["this is ours"]
      LambdaChooser.new(nil, :ours, :yours, :theirs) {
        on :ours, "this is ours"
        on [:theirs, :yours], "this is theirs or yours"
      }.choose([:theirs, :ours], :on).should == ["this is theirs or yours"]
      LambdaChooser.new(nil, :ours, :yours, :theirs) {
        on :ours, "this is ours"
        on [:theirs, :yours], "this is theirs or yours"
      }.choose([:yours, :ours], :on).should == ["this is theirs or yours"]
    end
  end

  it "should reject :otherwise as a choice name" do
    L{
      LambdaChooser.new(nil, :ours, :yours, :otherwise)
    }.should raise_error(ArgumentError, "You can't use :otherwise as a choice name, because it's reserved.")
  end

  it "should pick 'otherwise' if no choices match" do
    LambdaChooser.new(nil, :ours, :yours, :theirs) {
      on :ours, "this is ours"
      on :yours, "this is yours"
      otherwise "this is the default"
    }.choose(:theirs, :on).should == ["this is the default"]
  end

  it "should return 'nil' if no choices match and there's no 'otherwise'" do
    LambdaChooser.new(nil, :ours, :yours, :theirs) {
      on :yours, "this is yours"
      on :ours, "this is ours"
    }.choose(:theirs, :on).should == nil
  end

  it "should not join lists from multiple choices" do
    LambdaChooser.new(
      nil,
      :apt, :brew, :yum, :linux, :osx, :ubuntu, :debian, :osx, :karmic, :gutsy, :lucid, :intrepid, :dapper, :breezy, :jaunty, :feisty, :edgy, :warty, :hardy, :maverick, :hoary, :lenny, :snow_leopard, :panther, :tiger, :leopard
    ) {
      on :maverick, %w[ruby ruby1.8-dev]
      on :apt, %w[ruby irb ruby1.8-dev libopenssl-ruby]
    }.choose(
      [:maverick, :ubuntu, :apt, :linux, :all],
      :on
    ).should == %w[ruby ruby1.8-dev]
  end

  it "should default the choice method to #on" do
    LambdaChooser.new(nil, :ours, :theirs) {
      on :ours, "this is ours"
      on :theirs, "this is theirs"
    }.choose(:ours).should == ["this is ours"]
  end

  it "should accept a custom choice method" do
    LambdaChooser.new(nil, :ours, :theirs) {
      via :ours, "this is ours"
      via :theirs, "this is theirs"
    }.choose(:ours, :via).should == ["this is ours"]
  end

  it "should still respond to #on when a custom method is passed" do
    LambdaChooser.new(nil, :ours, :theirs) {
      on :ours, "this is ours"
      on :theirs, "this is theirs"
    }.choose(:ours, :via).should == ["this is ours"]
  end

  it "should reject values and block together" do
    L{
      LambdaChooser.new(nil, :ours, :theirs) {
        on :ours, "this is ours"
        on :theirs, "this is theirs" do
          'another value'
        end
      }.choose(:ours, :on)
    }.should raise_error("You can supply values or a block, but not both.")
  end

  it "should reject unknown choosers" do
    L{
      LambdaChooser.new(nil, :ours, :theirs) {
        on :ours, "this is ours"
        on :someone_elses, "this is theirs"
      }.choose(:ours, :on)
    }.should raise_error("The choice 'someone_elses' isn't valid.")
  end

  it "should return the data intact" do
    {
      "string" => ["string"],
      %w[a r r a y] => %w[a r r a y],
      {:h => 'a', :s => 'h'} => {:h => 'a', :s => 'h'}
    }.each_pair {|input, expected|
      LambdaChooser.new(nil, :ours, :theirs) {
        on :ours, input
        on :theirs, "this is theirs"
      }.choose(:ours, :on).should == expected
    }
  end

  it "should return DepRequirement input intact" do
    LambdaChooser.new(nil, :ours, :theirs) {
      on :ours, 'a dep'.with('an arg'), 'another dep'.with('another arg')
    }.choose(:ours, :on).should == [
      DepRequirement.new('a dep', ['an arg']),
      DepRequirement.new('another dep', ['another arg'])
    ]
  end

end
