require 'spec_helper'


describe "lambda choosing" do
  it "should return the value of the block when there are no choices" do
    expect(Babushka::LambdaChooser.new(nil, :ours, :theirs) {
      "block value"
    }.choose(:ours, :on)).to eq("block value")
  end

  it "should choose the specified call" do
    expect(Babushka::LambdaChooser.new(nil, :ours, :theirs) {
      on :ours, "this is ours"
      on :theirs, "this is theirs"
      "block value should be ignored"
    }.choose(:ours, :on)).to eq(["this is ours"])
  end

  it "should pick the first choice from multiple choices" do
    expect(Babushka::LambdaChooser.new(nil, :ours, :yours, :theirs) {
      on :ours, "this is ours"
      on :yours, "this is yours"
      on :theirs, "this is theirs"
    }.choose([:ours, :yours], :on)).to eq(["this is ours"])
    expect(Babushka::LambdaChooser.new(nil, :ours, :yours, :theirs) {
      on :yours, "this is yours"
      on :ours, "this is ours"
      on :theirs, "this is theirs"
    }.choose([:ours, :yours], :on)).to eq(["this is ours"])
  end

  context "with multiple targets" do
    it "should choose the specified call" do
      expect(Babushka::LambdaChooser.new(nil, :ours, :theirs, :yours) {
        on :ours, "this is ours"
        on [:theirs, :yours], "this is theirs or yours"
        "block value should be ignored"
      }.choose(:yours, :on)).to eq(["this is theirs or yours"])
    end
    it "should pick the first choice from multiple choices" do
      expect(Babushka::LambdaChooser.new(nil, :ours, :yours, :theirs) {
        on :ours, "this is ours"
        on [:theirs, :yours], "this is theirs or yours"
      }.choose([:ours, :yours], :on)).to eq(["this is ours"])
      expect(Babushka::LambdaChooser.new(nil, :ours, :yours, :theirs) {
        on :ours, "this is ours"
        on [:theirs, :yours], "this is theirs or yours"
      }.choose([:theirs, :ours], :on)).to eq(["this is theirs or yours"])
      expect(Babushka::LambdaChooser.new(nil, :ours, :yours, :theirs) {
        on :ours, "this is ours"
        on [:theirs, :yours], "this is theirs or yours"
      }.choose([:yours, :ours], :on)).to eq(["this is theirs or yours"])
    end
  end

  it "should reject :otherwise as a choice name" do
    expect(L{
      Babushka::LambdaChooser.new(nil, :ours, :yours, :otherwise)
    }).to raise_error(ArgumentError, "You can't use :otherwise as a choice name, because it's reserved.")
  end

  it "should pick 'otherwise' if no choices match" do
    expect(Babushka::LambdaChooser.new(nil, :ours, :yours, :theirs) {
      on :ours, "this is ours"
      on :yours, "this is yours"
      otherwise "this is the default"
    }.choose(:theirs, :on)).to eq(["this is the default"])
  end

  it "should return 'nil' if no choices match and there's no 'otherwise'" do
    expect(Babushka::LambdaChooser.new(nil, :ours, :yours, :theirs) {
      on :yours, "this is yours"
      on :ours, "this is ours"
    }.choose(:theirs, :on)).to eq(nil)
  end

  it "should not join lists from multiple choices" do
    expect(Babushka::LambdaChooser.new(
      nil,
      :osx, :linux, :brew, :apt, :ubuntu, :yosemite, :hardy, :maverick, :hoary
    ) {
      on :maverick, %w[ruby ruby1.8-dev]
      on :apt, %w[ruby irb ruby1.8-dev libopenssl-ruby]
    }.choose(
      [:maverick, :ubuntu, :apt, :linux, :all],
      :on
    )).to eq(%w[ruby ruby1.8-dev])
  end

  it "should default the choice method to #on" do
    expect(Babushka::LambdaChooser.new(nil, :ours, :theirs) {
      on :ours, "this is ours"
      on :theirs, "this is theirs"
    }.choose(:ours)).to eq(["this is ours"])
  end

  it "should accept a custom choice method" do
    expect(Babushka::LambdaChooser.new(nil, :ours, :theirs) {
      via :ours, "this is ours"
      via :theirs, "this is theirs"
    }.choose(:ours, :via)).to eq(["this is ours"])
  end

  it "should still respond to #on when a custom method is passed" do
    expect(Babushka::LambdaChooser.new(nil, :ours, :theirs) {
      on :ours, "this is ours"
      on :theirs, "this is theirs"
    }.choose(:ours, :via)).to eq(["this is ours"])
  end

  it "should reject values and block together" do
    expect(L{
      Babushka::LambdaChooser.new(nil, :ours, :theirs) {
        on :ours, "this is ours"
        on :theirs, "this is theirs" do
          'another value'
        end
      }.choose(:ours, :on)
    }).to raise_error("You can supply values or a block, but not both.")
  end

  it "should reject unknown choosers" do
    expect(L{
      Babushka::LambdaChooser.new(nil, :ours, :theirs) {
        on :ours, "this is ours"
        on :someone_elses, "this is theirs"
      }.choose(:ours, :on)
    }).to raise_error("The choice 'someone_elses' isn't valid.")
  end

  it "should return the data intact" do
    {
      "string" => ["string"],
      %w[a r r a y] => %w[a r r a y],
      {:h => 'a', :s => 'h'} => {:h => 'a', :s => 'h'}
    }.each_pair {|input, expected|
      expect(Babushka::LambdaChooser.new(nil, :ours, :theirs) {
        on :ours, input
        on :theirs, "this is theirs"
      }.choose(:ours, :on)).to eq(expected)
    }
  end

  it "should return DepRequirement input intact" do
    expect(Babushka::LambdaChooser.new(nil, :ours, :theirs) {
      on :ours, 'a dep'.with('an arg'), 'another dep'.with('another arg')
    }.choose(:ours, :on)).to eq([
      Babushka::DepRequirement.new('a dep', ['an arg']),
      Babushka::DepRequirement.new('another dep', ['another arg'])
    ])
  end

end
