require 'spec/spec_support'


describe "lambda choosing" do
  it "should choose the block value if there are no calls" do
    LambdaChooser.new { "value" }.choose.should == "value"
  end

  it "should choose the specified call" do
    LambdaChooser.new {
      ours "this is ours"
      theirs "this is theirs"
    }.choose(:ours).should == ["this is ours"]
  end

  it "should return the data intact" do
    {
      "string" => ["string"],
      %w[a r r a y] => %w[a r r a y],
      {:h => 'a', :s => 'h'} => {:h => 'a', :s => 'h'}
    }.each_pair {|input, expected|
      LambdaChooser.new {
        ours input
        theirs "this is theirs"
      }.choose(:ours).should == expected
    }
  end
  
end
