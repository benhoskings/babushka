require 'sources_support'

describe "adding" do
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
  describe "with local changes" do
    before {
      @source_def = dep_source 'changes_test'
      @source = Source.new(@source_def)
      @source.add!
    }
    it "shouldn't remove sources with local changes" do
      File.open(@source.path / 'changes_test.rb', 'w') {|f| f << 'modification' }
      L{ Source.remove!(@source_def) }.should change(Source, :count).by(0)
      Source.sources.should include @source_def
    end
    it "shouldn't remove sources with untracked files" do
      File.open(@source.path / 'changes_test_untracked.rb', 'w') {|f| f << 'modification' }
      L{ Source.remove!(@source_def) }.should change(Source, :count).by(0)
      Source.sources.should include @source_def
    end
    it "shouldn't remove sources with unpushed commits" do
      File.open(@source.path / 'changes_test.rb', 'w') {|f| f << 'modification' }
      Dir.chdir(@source.path) { shell "git commit -a -m 'update from spec'" }
      L{ Source.remove!(@source_def) }.should change(Source, :count).by(0)
      Source.sources.should include @source_def
    end
    it "should remove dirty sources when :force is specified" do
      File.open(@source.path / 'changes_test.rb', 'w') {|f| f << 'modification' }
      File.open(@source.path / 'changes_test_untracked.rb', 'w') {|f| f << 'modification' }
      L{ Source.remove!(@source_def, :force => true) }.should change(Source, :count).by(-1)
      Source.sources.should_not include @source_def
    end
    after {
      Source.clear! :force => true
    }
  end
end

describe "clearing" do
  before {
    Source.new(dep_source('clear_test_1')).add!
    Source.new(dep_source('clear_test_2')).add!
  }
  it "should remove all sources" do
    Source.count.should == 2
    Source.clear!
    Source.count.should == 0
  end
end
