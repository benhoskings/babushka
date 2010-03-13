require 'spec_support'
require 'sources_support'

describe "adding" do
  it "shouldn't add unreadable sources" do
    L{
      Source.add!('unreadable', tmp_prefix / "nonexistent.git")
    }.should_not change(Source, :count)
    Source.new(:name => 'unreadable').path.exists?.should be_false
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
  describe "external sources" do
    before {
      @source = dep_source('bob').merge(:external => true)
      @nonexistent_source = {:name => 'larry', :uri => tmp_prefix / 'nonexistent', :external => true}
    }
    it "shouldn't clone nonexistent repos" do
      File.exists?(Source.new(@nonexistent_source).path).should be_false
      L{ Source.add_external!(@nonexistent_source[:name], :from => :github).should be_nil }.should_not change(Source, :count)
      File.directory?(Source.new(@nonexistent_source).path).should be_false
    end
    it "should clone a git repo" do
      File.exists?(Source.new(@source).path).should be_false
      L{ Source.add_external!(@source[:name], :from => :github).should be_an_instance_of(Source) }.should_not change(Source, :count)
      File.directory?(Source.new(@source).path).should be_true
    end
    it "shouldn't add the url to sources.yml" do
      Source.sources.should be_empty
      L{ Source.add_external!(@source[:name], :from => :github) }.should_not change(Source, :count)
      Source.sources.should be_empty
    end
    after {
      Source.clear! :force => true
    }
  end
end

describe "removing" do
  before {
    @source1 = dep_source 'remove_test'
    @source2 = dep_source 'remove_test_yml'
    Source.new(@source1).add!
    Source.new(@source2).add!
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
