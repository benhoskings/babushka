require 'spec_support'
require 'sources_support'

describe Source, '.discover_uri_and_type' do
  it "should label nil paths as implicit" do
    Source.discover_uri_and_type(nil).should == [nil, 'implicit']
  end
  it "should work for public uris" do
    [
      'git://github.com/benhoskings/babushka-deps.git',
      'http://github.com/benhoskings/babushka-deps.git',
      'file://Users/ben/babushka/deps'
    ].each {|uri|
      Source.discover_uri_and_type(uri).should == [URI.parse(uri), 'public']
    }
  end
  it "should work for private uris" do
    [
      'git@github.com:benhoskings/babushka-deps.git',
      'benhoskin.gs:~ben/babushka-deps.git'
    ].each {|uri|
      Source.discover_uri_and_type(uri).should == [uri, 'private']
    }
  end
  it "should work for local paths" do
    Source.discover_uri_and_type('~/.babushka/deps').should == ['~/.babushka/deps'.p, 'local']
    Source.discover_uri_and_type('/tmp/babushka_deps').should == ['/tmp/babushka_deps', 'local']
  end
end

describe Source, '#uri_matches?' do
  it "should match on equivalent URIs" do
    Source.new(nil).uri_matches?(nil).should be_true
    Source.new('~/.babushka/deps').uri_matches?('~/.babushka/deps').should be_true
    Source.new('git://github.com/benhoskings/babushka-deps.git').uri_matches?('git://github.com/benhoskings/babushka-deps.git').should be_true
    Source.new('git@github.com:benhoskings/babushka-deps.git').uri_matches?('git@github.com:benhoskings/babushka-deps.git').should be_true
  end
  it "should not match on differing URIs" do
    Source.new(nil).uri_matches?('').should be_false
    Source.new('~/.babushka/deps').uri_matches?('~/.babushka/babushka_deps').should be_false
    Source.new('git://github.com/benhoskings/babushka-deps.git').uri_matches?('http://github.com/benhoskings/babushka-deps.git').should be_false
    Source.new('git://github.com/benhoskings/babushka-deps.git').uri_matches?('git://github.com/benhoskings/babushka-deps').should be_false
    Source.new('git@github.com:benhoskings/babushka-deps.git').uri_matches?('github.com:benhoskings/babushka-deps.git').should be_false
    Source.new('git@github.com:benhoskings/babushka-deps.git').uri_matches?('git@github.com:benhoskings/babushka-deps').should be_false
  end
end

describe "loading deps" do
  it "should load deps from a file" do
    source = Source.new('spec/deps/good')
    source.load!.should be_true
    source.deps.names.should include('test dep 1')
  end
  it "should recover from load errors" do
    source = Source.new('spec/deps/bad')
    source.load!.should be_true
    source.deps.names.should_not include('broken test dep 1')
  end
  it "should store the source the dep was loaded from" do
    source = Source.new('spec/deps/good')
    source.load!
    source.deps.deps.first.dep_source.should == source
  end
end

describe "finding" do
  it "should find the specified dep" do
    source = Source.new('spec/deps/good')
    source.load!.should be_true
    source.find('test dep 1').should == source.deps.deps.first
  end
end

describe "adding" do
  it "shouldn't add unreadable sources" do
    L{
      Source.add!(tmp_prefix / "nonexistent.git", :name => 'unreadable')
    }.should_not change(Source, :count)
    (tmp_prefix / 'sources' / 'unreadable').exists?.should be_false
  end
  describe "cloning" do
    before { @source = test_dep_source 'clone_test' }
    it "should clone a git repo" do
      File.exists?(Source.new(*@source).path).should be_false
      L{ Source.add!(*@source) }.should change(Source, :count).by(1)
      File.directory?(Source.new(*@source).path / '.git').should be_true
    end
    it "should be cloned into the source prefix" do
      Source.add!(*@source)
      Source.new(*@source).path.to_s.starts_with?((tmp_prefix / 'sources').p.to_s).should be_true
    end
  end
  describe "classification" do
    before { @source = test_dep_source 'classification_test' }
    it "should treat file:// as public" do
      (source = Source.new(*@source)).add!
      source.send(:yaml_attributes).should == {:uri => @source.first, :name => 'classification_test', :type => 'public'}
    end
    it "should treat local paths as local" do
      (source = Source.new(@source.first.gsub(/^file:\//, ''), @source.last)).add!
      source.send(:yaml_attributes).should == {:uri => @source.first.gsub(/^file:\//, ''), :name => 'classification_test', :type => 'local'}
    end
    it "should be cloned into the source prefix" do
      Source.add!(*@source)
      Source.new(*@source).path.to_s.starts_with?((tmp_prefix / 'sources').p.to_s).should be_true
    end
  end
  describe "adding to sources.yml" do
    before { @source = test_dep_source 'clone_test_yml' }
    it "should add the url to sources.yml" do
      Source.sources.should_not include @source
      L{ Source.add!(*@source) }.should change(Source, :count).by(1)
      Source.sources.should include({:uri => @source.first, :name => 'clone_test_yml', :type => 'public'})
    end
  end
  describe "external sources" do
    before {
      @source = test_dep_source('bob').merge(:external => true)
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
    @source1 = test_dep_source 'remove_test'
    @source2 = test_dep_source 'remove_test_yml'
    Source.new(*@source1).add!
    Source.new(*@source2).add!
  }
  it "should remove just the specified source" do
    L{ Source.remove!(*@source1) }.should change(Source, :count).by(-1)
    Source.sources.should_not include({:uri => @source1.first, :name => 'remove_test'})
    Source.sources.should include({:uri => @source2.first, :name => 'remove_test_yml', :type => 'public'})
  end
  describe "with local changes" do
    before {
      @source_def = test_dep_source 'changes_test'
      @source = Source.new(*@source_def)
      @source.add!
    }
    it "shouldn't remove sources with local changes" do
      File.open(@source.path / 'changes_test.rb', 'w') {|f| f << 'modification' }
      L{ Source.remove!(*@source_def) }.should change(Source, :count).by(0)
      Source.sources.should include({:uri => @source_def.first, :name => 'changes_test', :type => 'public'})
    end
    it "shouldn't remove sources with untracked files" do
      File.open(@source.path / 'changes_test_untracked.rb', 'w') {|f| f << 'modification' }
      L{ Source.remove!(*@source_def) }.should change(Source, :count).by(0)
      Source.sources.should include({:uri => @source_def.first, :name => 'changes_test', :type => 'public'})
    end
    it "shouldn't remove sources with unpushed commits" do
      File.open(@source.path / 'changes_test.rb', 'w') {|f| f << 'modification' }
      Dir.chdir(@source.path) { shell "git commit -a -m 'update from spec'" }
      L{ Source.remove!(*@source_def) }.should change(Source, :count).by(0)
      Source.sources.should include({:uri => @source_def.first, :name => 'changes_test', :type => 'public'})
    end
    it "should remove dirty sources when :force is specified" do
      File.open(@source.path / 'changes_test.rb', 'w') {|f| f << 'modification' }
      File.open(@source.path / 'changes_test_untracked.rb', 'w') {|f| f << 'modification' }
      L{ Source.remove!(@source_def.first, @source_def.last.merge(:force => true)) }.should change(Source, :count).by(-1)
      Source.sources.should_not include({:uri => @source_def.first, :name => 'changes_test', :type => 'public'})
    end
    after {
      Source.clear! :force => true
    }
  end
end

describe "clearing" do
  before {
    Source.new(*test_dep_source('clear_test_1')).add!
    Source.new(*test_dep_source('clear_test_2')).add!
  }
  it "should remove all sources" do
    Source.count.should == 2
    Source.clear!
    Source.count.should == 0
  end
end
