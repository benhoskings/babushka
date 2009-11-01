require 'spec/sources_support'

describe "adding sources" do
  it "shouldn't add unreadable sources" do
    L{
      Source.add!('unreadable', tmp_prefix / "nonexistent.git")
    }.should_not change(Source, :count)
  end
  describe "cloning" do
    before { @source = dep_source 'clone_test' }
    it "should clone a git repo" do
      File.exists?(Source.new(@source).path).should be_false
      L{ Source.add!(@source[:name], @source[:uri]) }.should change(Source, :count).by(1)
      File.directory?(Source.new(@source).path / '.git').should be_true
    end
  end
  describe "adding to sources.yml" do
    before { @source = dep_source 'clone_test_yml' }
    it "should add the url to sources.yml" do
      Source.sources.should_not include @source
      L{ Source.add!(@source[:name], @source[:uri]) }.should change(Source, :count).by(1)
      Source.sources.should include @source
    end
  end

  describe "removing" do
    before {
      @source1 = dep_source 'clone_test'
      @source2 = dep_source 'clone_test_yml'
    }
    it "should remove just the specified source" do
      Source.sources.should include @source1
      L{ Source.remove!(@source1) }.should change(Source, :count).by(-1)
      Source.sources.should_not include @source1
      Source.sources.should include @source2
    end
  end
  
  describe "clearing" do
    it "should remove all sources" do
      Source.clear!
      Source.count.should == 0
    end
  end
end
