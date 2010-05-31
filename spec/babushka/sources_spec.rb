require 'spec_support'
require 'sources_support'

describe Source, "arguments" do
  it "should reject non-hash options" do
    L{
      Source.new 'a', 'b'
    }.should raise_error ArgumentError, 'Source.new options must be passed as a hash, not as "b".'
  end
end

describe Source, '.discover_uri_and_type' do
  it "should label nil paths as implicit" do
    Source.discover_uri_and_type(nil).should == [nil, :implicit]
  end
  it "should work for public uris" do
    [
      'git://github.com/benhoskings/babushka-deps.git',
      'http://github.com/benhoskings/babushka-deps.git',
      'file://Users/ben/babushka/deps'
    ].each {|uri|
      Source.discover_uri_and_type(uri).should == [URI.parse(uri), :public]
    }
  end
  it "should work for private uris" do
    [
      'git@github.com:benhoskings/babushka-deps.git',
      'benhoskin.gs:~ben/babushka-deps.git'
    ].each {|uri|
      Source.discover_uri_and_type(uri).should == [uri, :private]
    }
  end
  it "should work for local paths" do
    Source.discover_uri_and_type('~/.babushka/deps').should == ['~/.babushka/deps'.p, :local]
    Source.discover_uri_and_type('/tmp/babushka_deps').should == ['/tmp/babushka_deps', :local]
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

describe Source, '#path' do
  it "should work for implicit sources" do
    Source.new(nil).path.should == nil
  end
  it "should work for local sources" do
    Source.new('~/.babushka/deps').path.should == '~/.babushka/deps'.p
  end
  context "cloneable repos" do
    context "without names" do
      it "should work for public sources" do
        Source.new('git://github.com/benhoskings/babushka-deps.git').path.should == tmp_prefix / 'sources/babushka-deps'
      end
      it "should work for private sources" do
        Source.new('git@github.com:benhoskings/babushka-deps.git').path.should == tmp_prefix / 'sources/babushka-deps'
      end
    end
    context "with names" do
      it "should work for public sources" do
        Source.new('git://github.com/benhoskings/babushka-deps.git', :name => 'custom_public_deps').path.should == tmp_prefix / 'sources/custom_public_deps'
      end
      it "should work for private sources" do
        Source.new('git@github.com:benhoskings/babushka-deps.git', :name => 'custom_private_deps').path.should == tmp_prefix / 'sources/custom_private_deps'
      end
    end
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

describe "equality" do
  before {
    @remote_1 = test_dep_source 'equality_1'
    @remote_2 = test_dep_source 'equality_2'
  }
  it "should be equal when uri, name and type are the same" do
    (Source.new(@remote_1) == Source.new(@remote_1)).should be_true
  end
  it "shouldn't be equal when the name differs" do
    (Source.new(@remote_1) == Source.new(@remote_1, :name => 'remote_other')).should be_false
  end
  it "shouldn't be equal when the uri differs" do
    (Source.new(@remote_1) == Source.new(@remote_2, :name => 'remote_1')).should be_false
  end
end

describe Source, ".for_path" do
  context "on a file" do
    before { `touch "#{tmp_prefix / 'sources/regular_file'}"` }
    it "should raise when called on a file" do
      L{
        Source.for_path(Source.source_prefix / 'regular_file')
      }.should raise_error(ArgumentError, "The path #{Source.source_prefix / 'regular_file'} isn't a directory.")
    end
  end
  context "on a dir" do
    before {
      `mkdir -p "#{tmp_prefix / 'ad_hoc_source'}"`
      @source = Source.for_path(tmp_prefix / 'ad_hoc_source')
    }
    it "should work on a dir" do
      @source.should be_present
      @source.path.should == tmp_prefix / 'ad_hoc_source'
      @source.name.should == 'ad_hoc_source'
    end
  end
  context "on a git repo" do
    before {
      remote = test_dep_source 'for_path_remote'
      Source.new(remote.first).add!
      @source = Source.for_path(Source.source_prefix / 'for_path_remote')
    }
    it "should work on a git repo" do
      @source.should be_present
      @source.path.should == Source.source_prefix / 'for_path_remote'
      @source.name.should == 'for_path_remote'
    end
    after { @source.remove! :force => true }
  end
end

describe Source, '.present' do
  before {
    @source_1 = Source.new(*test_dep_source('present_remote_1'))
    @source_1.add!
    @source_2 = Source.new(*test_dep_source('present_remote_2'))
    @source_2.add!
    @source_3 = Source.new(*test_dep_source('present_remote_3'))
  }
  it "should return the sources that are present" do
    Source.present.should == [@source_1, @source_2]
  end
end

describe "finding" do
  it "should find the specified dep" do
    source = Source.new('spec/deps/good')
    source.load!.should be_true
    source.find('test dep 1').should == source.deps.deps.first
  end
end

describe Source, "#present?" do
  context "for local repos" do
    it "should be true for valid paths" do
      Source.new('spec/deps/good').should be_present
    end
    it "should be false for invalid paths" do
      Source.new('spec/deps/nonexistent').should_not be_present
    end
  end
  context "for remote repos" do
    before { @present_source = test_dep_source 'present' }
    it "should be false" do
      Source.new(@present_source.first).should_not be_present
    end
    context "after cloning" do
      before { Source.new(@present_source.first).add! }
      it "should be true" do
        Source.new(@present_source.first).should be_present
      end
    end
  end
end

describe "cloning" do
  context "unreadable sources" do
    before {
      @source = Source.new(tmp_prefix / "nonexistent.git", :name => 'unreadable')
      @source.add!
    }
    it "shouldn't work" do
      @source.path.should_not be_exists
    end
  end

  context "readable sources" do
    before {
      @source = Source.new(*test_dep_source('clone_test'))
    }
    it "should clone a git repo" do
      @source.path.should_not be_exists
      @source.add!
      @source.path.should be_exists
    end
    it "should be available in Base.sources" do
      Base.sources.current.taph.include?(@source).should be_true
    end
    it "should be cloned into the source prefix" do
      @source.path.to_s.starts_with?((tmp_prefix / 'sources').p.to_s).should be_true
    end

    context "without a name" do
      before {
        @nameless = Source.new(test_dep_source('nameless').first)
        @nameless.add!
      }
      it "should use the basename as the name" do
        File.directory?(tmp_prefix / 'sources/nameless').should be_true
      end
      it "should set the name in the source" do
        @nameless.name.should == 'nameless'
      end
    end
    context "with a name" do
      before {
        @aliased = Source.new(test_dep_source('aliased').first, :name => 'an_aliased_source')
        @aliased.add!
      }
      it "should override the name" do
        File.directory?(tmp_prefix / 'sources/an_aliased_source').should be_true
      end
      it "should set the name in the source" do
        @aliased.name.should == 'an_aliased_source'
      end
    end
    context "duplication" do
      before {
        @remote = test_dep_source 'duplicate_test'
        @dup_remote = test_dep_source 'duplicate_dup'
        @source = Source.new @remote.first
        @source.add!
      }
      context "with the same name and URL" do
        before {
          @dup_source = Source.new(@remote.first, :name => 'duplicate_test')
        }
        it "should work" do
          L{ @dup_source.add! }.should_not raise_error
          @dup_source.should == @source
        end
      end
      context "with the same name and different URLs" do
        it "should raise an exception and not add anything" do
          @dup_source = Source.new(@dup_remote.first, :name => 'duplicate_test')
          L{
            @dup_source.add!
          }.should raise_error("There is already a source called '#{@source.name}' (it contains #{@source.uri}).")
        end
      end
      context "with the same URL and different names" do
        it "should raise an exception and not add anything" do
          @dup_source = Source.new(@remote.first, :name => 'duplicate_test_different_name')
          L{
            @dup_source.add!
          }.should raise_error("The source #{@source.uri} is already present (as '#{@source.name}').")
        end
      end
    end
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
    Base.sources.clear! :force => true
  }
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
      Base.sources.clear! :force => true
    }
  end
end

describe "clearing" do
  before {
    Source.new(*test_dep_source('clear_test_1')).add!
    Source.new(*test_dep_source('clear_test_2')).add!
  }
  it "should remove all sources" do
    Base.sources.count.should == 2
    Base.sources.clear!
    Base.sources.count.should == 0
  end
end
