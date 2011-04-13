require 'spec_helper'
require 'source_support'

describe Source, "arguments" do
  it "should reject non-hash options" do
    L{
      Source.new 'a', 'b'
    }.should raise_error(ArgumentError, 'Source.new options must be passed as a hash, not as "b".')
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
      'file:///Users/ben/babushka/deps'
    ].each {|uri|
      Source.discover_uri_and_type(uri).should == [uri, :public]
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
    Source.discover_uri_and_type('/tmp/babushka-deps').should == ['/tmp/babushka-deps', :local]
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
    Source.new('~/.babushka/deps').uri_matches?('~/.babushka/babushka-deps').should be_false
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
  context "with a good source" do
    before {
      @source = Source.new('spec/deps/good')
      Base.task.verb = Babushka::Base::PassedVerb.new nil, {}, [], {}
      @source.stub!(:define_deps!)
      @source.load!
    }
    it "should load deps from a file" do
      @source.deps.names.should include('test dep 1')
      @source.deps.names.should include('test dep 2')
    end
    it "should not have defined the deps" do
      dep = @source.deps.for('test dep 1')
      dep.dep_defined?.should be_false
    end
    it "should store the source the dep was loaded from" do
      @source.deps.for('test dep 1').dep_source.should == @source
    end
  end
  context "with a source with errors" do
    before {
      @source = Source.new('spec/deps/bad')
      @source.stub!(:define_deps!)
      @source.load!
    }
    it "should recover from load errors" do
      @source.deps.names.should include('broken test dep 1')
      @source.deps.names.should include('test dep 1')
    end
  end
end

describe "defining deps" do
  before {
    @source = Source.new('spec/deps/good')
    @source.load!
  }
  context "after loading" do
    before {
      @dep = @source.deps.for('test dep 1')
    }
    it "should not have defined the deps" do
      @dep.dep_defined?.should == nil
    end
  end
end

describe "equality" do
  before {
    @remote_1 = make_source_remote 'equality_1'
    @remote_2 = make_source_remote 'equality_2'
  }
  it "should be equal when uri, name and type are the same" do
    (Source.new(*@remote_1) == Source.new(*@remote_1)).should be_true
  end
  it "shouldn't be equal when the name differs" do
    (Source.new(*@remote_1) == Source.new(@remote_1.first, :name => 'remote_other')).should be_false
  end
  it "shouldn't be equal when the uri differs" do
    (Source.new(*@remote_1) == Source.new(@remote_2.first, :name => 'remote_1')).should be_false
  end
end

describe Source, ".for_path" do
  context "on a file" do
    before {
      `mkdir -p "#{tmp_prefix / 'sources'}"`
      `touch "#{tmp_prefix / 'sources/regular_file'}"`
    }
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
      remote = make_source_remote 'path_remote_test'
      Source.new(remote.first).add!
      @source = Source.for_path(Source.source_prefix / 'path_remote_test')
    }
    it "should work on a git repo" do
      @source.should be_present
      @source.path.should == Source.source_prefix / 'path_remote_test'
      @source.name.should == 'path_remote_test'
    end
    after { @source.remove! }
  end
  context "on a git repo with a custom name" do
    before {
      remote = make_source_remote 'custom_path_remote_test'
      Source.new(remote.first, :name => 'custom_name_test').add!
      @source = Source.for_path(Source.source_prefix / 'custom_name_test')
    }
    it "should work on a git repo" do
      @source.should be_present
      @source.path.should == Source.source_prefix / 'custom_name_test'
      @source.name.should == 'custom_name_test'
    end
    after { @source.remove! }
  end
end

describe Source, '.present' do
  before {
    @source_1 = Source.new(*make_source_remote('present_remote_1_test'))
    @source_1.add!
    @source_2 = Source.new(*make_source_remote('present_remote_2_test'))
    @source_2.add!
    @source_3 = Source.new(*make_source_remote('present_remote_3_test'))
  }
  it "should return the sources that are present" do
    Source.present.should =~ [@source_1, @source_2]
  end
end

describe "finding" do
  before {
    @source = Source.new('spec/deps/good')
    @source.load!
  }
  it "should find the specified dep" do
    @source.find('test dep 1').should be_an_instance_of(Dep)
    @source.deps.deps.include?(@source.find('test dep 1')).should be_true
  end
  it "should find the specified template" do
    @source.find_template('test meta 1').should be_an_instance_of(MetaDep)
    @source.templates.templates.include?(@source.find_template('test meta 1')).should be_true
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
    before { @present_source = make_source_remote 'present_test' }
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
      @source = Source.new(*make_source_remote('clone_test'))
    }
    it "should clone a git repo" do
      @source.path.should_not be_exists
      @source.add!
      @source.path.should be_exists
    end
    it "should not be available in Base.sources" do
      Base.sources.current.include?(@source).should be_false
    end
    it "should be cloned into the source prefix" do
      @source.path.to_s.starts_with?((tmp_prefix / 'sources').p.to_s).should be_true
    end

    context "without a name" do
      before {
        @nameless = Source.new(make_source_remote('nameless_test').first)
        @nameless.add!
      }
      it "should use the basename as the name" do
        File.directory?(tmp_prefix / 'sources/nameless_test').should be_true
      end
      it "should set the name in the source" do
        @nameless.name.should == 'nameless_test'
      end
    end
    context "with a name" do
      before {
        @fancypath_name = 'aliased_source_test'.p.basename
        @aliased = Source.new(make_source_remote('aliased').first, :name => @fancypath_name)
        @aliased.add!
      }
      it "should override the name" do
        File.directory?(tmp_prefix / 'sources/aliased_source_test').should be_true
      end
      it "should set the name in the source" do
        @aliased.name.should == 'aliased_source_test'
      end
      it "should stringify the name" do
        @fancypath_name.should be_an_instance_of(Fancypath)
        @aliased.name.should be_an_instance_of(String)
      end
    end
    context "duplication" do
      before {
        @remote = make_source_remote 'duplicate_test'
        @dup_remote = make_source_remote 'duplicate_dup'
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
          }.should raise_error(SourceError, "There is already a source called '#{@source.name}' (it contains #{@source.uri}).")
        end
      end
      context "with the same URL and different names" do
        it "should raise an exception and not add anything" do
          @dup_source = Source.new(@remote.first, :name => 'duplicate_test_different_name')
          L{
            @dup_source.add!
          }.should raise_error(SourceError, "The source #{@source.uri} is already present (as '#{@source.name}').")
        end
      end
    end
  end
end

describe "classification" do
  before { @source = make_source_remote 'classification_test' }
  it "should treat file:// as public" do
    (source = Source.new(*@source)).add!
    [source.uri, source.name, source.type].should == [@source.first, 'classification_test', :public]
  end
  it "should treat local paths as local" do
    (source = Source.new(@source.first.gsub(/^file:\/\//, ''), @source.last)).add!
    [source.uri, source.name, source.type].should == [@source.first.gsub(/^file:\/\//, ''), 'classification_test', :local]
  end
end
