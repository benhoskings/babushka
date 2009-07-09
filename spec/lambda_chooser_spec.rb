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
  
end
