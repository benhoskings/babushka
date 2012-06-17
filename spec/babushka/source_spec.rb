require 'spec_helper'
require 'source_support'

describe Source do
  before(:all) {
    @remote_1 = make_source_remote 'remote_1'
    @remote_2 = make_source_remote 'remote_2'
  }

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
    it "should treat URLs containing auth info as private" do
      [
        'http://ben@server.org/benhoskings/babushka.git',
        'https://ben:secret@server.org/benhoskings/babushka.git'
      ].each {|uri|
        Source.discover_uri_and_type(uri).should == [uri, :private]
      }
    end
    it "should treat git:// and friends as public" do
      [
        'git://github.com/benhoskings/babushka-deps.git',
        'http://github.com/benhoskings/babushka-deps.git',
        'https://github.com/benhoskings/babushka-deps.git',
        'file:///Users/ben/babushka/deps'
      ].each {|uri|
        Source.discover_uri_and_type(uri).should == [uri, :public]
      }
    end
    it "should treat ssh-style URLs as private" do
      [
        'git@github.com:benhoskings/babushka-deps.git',
        'benhoskin.gs:~ben/babushka-deps.git',
        'ben.local:/Users/ben/babushka-deps.git'
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

  describe Source, '#cloneable?' do
    it "should work for implicit sources" do
      Source.new(nil).should_not be_cloneable
    end
    it "should work for local sources" do
      Source.new('~/.babushka/deps').should_not be_cloneable
    end
    it "should work for public sources" do
      Source.new('git://github.com/benhoskings/babushka-deps.git').should be_cloneable
    end
    it "should work for private sources" do
      Source.new('git@github.com:benhoskings/babushka-deps.git').should be_cloneable
    end
  end

  describe "#cloned?" do
    it "should return false for implicit sources" do
      Source.new(nil).should_not be_cloned
    end
    it "should return false for local sources" do
      Source.new(nil).should_not be_cloned
    end
    context "for cloneable repos" do
      subject { Source.new(*@remote_2) }
      it "should not be cloned" do
        subject.should_not be_cloned
      end
      it "should be cloned after loading" do
        subject.load!
        subject.should be_cloned
      end
      after {
        subject.path.rm
      }
    end
  end

  describe "loading deps" do
    context "with a good source" do
      before {
        @source = Source.new('spec/deps/good')
        @source.load!
      }
      it "should load deps from a file" do
        @source.deps.names.should include('test dep 1')
        @source.deps.names.should include('test dep 2')
      end
      it "should not have defined the deps" do
        dep = @source.deps.for('test dep 1')
        dep.context.should_not be_loaded
      end
      it "should store the source the dep was loaded from" do
        @source.deps.for('test dep 1').dep_source.should == @source
      end
    end
    context "with a source with errors" do
      before {
        @source = Source.new('spec/deps/bad')
        @source.load!
      }
      it "should recover from load errors" do
        @source.deps.names.should include('broken test dep 1')
        @source.deps.names.should include('test dep 1')
      end
    end
  end

  describe "loading deps with parameters" do
    let(:source) { Source.new('spec/deps/params').tap(&:load!) }
    let(:requires) { source.deps.for('top-level dep with params').context.define!.requires }
    it "should store the right number of requirements" do
      requires.length.should == 2
    end
    it "should store the right kinds of objects" do
      requires.map(&:class).should == [String, Babushka::DepRequirement]
    end
    it "should store string requirements properly" do
      requires.first.should == 'a dep without params'
    end
    context "requirements" do
      let(:requirement) { requires.last }
      it "should store the name properly" do
        requirement.name.should == 'another dep with params'
      end
      context "arguments" do
        let(:args) { requirement.args }
        it "should store parameters" do
          args.map(&:class).should == [Parameter]
        end
        it "should store the name properly" do
          args.map(&:name).should == [:param]
        end
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
        @dep.context.should_not be_loaded
      end
    end
  end

  describe "equality" do
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
    let(:source) { Source.for_path(source_path) }
    context "on a file" do
      before {
        `mkdir -p "#{tmp_prefix / 'sources'}"`
        `touch "#{tmp_prefix / 'sources/regular_file'}"`
      }
      it "should raise when called on a file" do
        L{
          Source.for_path(Source.source_prefix / 'regular_file')
        }.should raise_error(Errno::ENOTDIR, "Not a directory - #{Source.source_prefix / 'regular_file'}")
      end
    end
    context "on a dir" do
      let(:source_path) { tmp_prefix / 'ad_hoc_source' }
      before {
        `mkdir -p "#{tmp_prefix / 'ad_hoc_source'}"`
      }
      it "should work on a dir" do
        source.should be_present
        source.path.should == tmp_prefix / 'ad_hoc_source'
        source.name.should == 'ad_hoc_source'
      end
      it "should cache the source" do
        Source.for_path(source_path).object_id.should == Source.for_path(source_path).object_id
      end
    end
    context "on a git repo" do
      let(:source_path) { Source.source_prefix / 'remote_1' }
      before {
        Source.new(@remote_1.first).add!
      }
      it "should work on a git repo" do
        source.should be_present
        source.path.should == Source.source_prefix / 'remote_1'
        source.name.should == 'remote_1'
      end
      it "should cache the source" do
        Source.for_path(source_path).object_id.should == Source.for_path(source_path).object_id
      end
      after { source.remove! }
    end
    context "on a git repo with a custom name" do
      let(:source_path) { Source.source_prefix / 'custom_name_test' }
      before {
        Source.new(@remote_1.first, :name => 'custom_name_test').add!
      }
      it "should work on a git repo" do
        source.should be_present
        source.path.should == Source.source_prefix / 'custom_name_test'
        source.name.should == 'custom_name_test'
      end
      it "should cache the source" do
        Source.for_path(source_path).object_id.should == Source.for_path(source_path).object_id
      end
      after { source.remove! }
    end
  end

  describe "finding" do
    before {
      @source = Source.new('spec/deps/good')
      @source.load!
    }
    it "should find the specified dep" do
      @source.find('test dep 1').should be_an_instance_of(Dep)
      @source.deps.items.include?(@source.find('test dep 1')).should be_true
    end
    it "should find the specified template" do
      @source.find_template('test_meta_1').should be_an_instance_of(MetaDep)
      @source.templates.items.include?(@source.find_template('test_meta_1')).should be_true
    end
  end

  describe Source, "#present?" do
    context "for local repos" do
      it "should be true for valid paths" do
        Source.new('spec/deps/good').should be_present
      end
      it "should be false for invalid paths" do
        Source.new('spec/deps/missing').should_not be_present
      end
    end
    context "for remote repos" do
      before {
        @source_1 = Source.new(*@remote_1)
        @source_2 = Source.new(*@remote_2)
      }
      it "should be false" do
        @source_1.should_not be_present
        Source.present.should == []
      end
      context "after cloning" do
        before {
          @source_1.add!
        }
        it "should be true" do
          @source_1.should be_present
          Source.present.should == [@source_1]
        end
        after {
          @source_1.remove!
        }
      end
    end
  end

  describe "cloning" do
    context "unreadable sources" do
      before {
        @source = Source.new(tmp_prefix / "missing.git", :name => 'unreadable')
        @source.add!
      }
      it "shouldn't work" do
        @source.path.should_not be_exists
      end
    end

    context "readable sources" do
      before(:all) {
        @source = Source.new(*@remote_1)
      }
      context "normally" do
        it "shouldn't be present yet" do
          @source.path.should_not be_exists
        end
        context "after adding" do
          before(:all) { @source.add! }
          it "should be present now" do
            @source.path.should be_exists
          end
          it "should not be available in Base.sources" do
            Base.sources.current.include?(@source).should be_false
          end
          it "should be cloned into the source prefix" do
            @source.path.to_s.starts_with?((tmp_prefix / 'sources').p.to_s).should be_true
          end
          after(:all) { @source.remove! }
        end
      end

      context "without a name" do
        before(:all) {
          @nameless = Source.new(@remote_1.first)
        }
        it "should use the basename as the name" do
          @nameless.should_receive(:git).with(@remote_1.first, :to => (tmp_prefix / 'sources/remote_1'), :log => true)
          @nameless.add!
        end
        it "should set the name in the source" do
          @nameless.name.should == 'remote_1'
        end
        after(:all) { @nameless.remove! }
      end
      context "with a name" do
        before(:all) {
          @fancypath_name = 'aliased_source_test'.p.basename
          @aliased = Source.new(@remote_1.first, :name => @fancypath_name)
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
        after(:all) { @aliased.remove! }
      end
      context "duplication" do
        before(:all) {
          @source = Source.new @remote_1.first
          @source.add!
        }
        context "with the same name and URL" do
          before {
            @dup_source = Source.new(@remote_1.first, :name => 'remote_1')
          }
          it "should work" do
            L{ @dup_source.add! }.should_not raise_error
            @dup_source.should == @source
          end
        end
        context "with the same name and different URLs" do
          it "should raise an exception and not add anything" do
            @dup_source = Source.new(@remote_2.first, :name => 'remote_1')
            L{
              @dup_source.add!
            }.should raise_error(SourceError, "There is already a source called '#{@source.name}' (it contains #{@source.uri}).")
          end
        end
        context "with the same URL and different names" do
          it "should raise an exception and not add anything" do
            @dup_source = Source.new(@remote_1.first, :name => 'duplicate_test_different_name')
            L{
              @dup_source.add!
            }.should raise_error(SourceError, "The source #{@source.uri} is already present (as '#{@source.name}').")
          end
        end
      end
    end
  end

  describe "updating" do
    before {
      @source = Source.new(*@remote_2)
    }
    it "should update when the source isn't cloned" do
      @source.should_receive(:update!)
      @source.load!
    end
    it "should not update when the source is already cloned" do
      @source.stub!(:cloned?).and_return(true)
      @source.should_not_receive(:update!)
      @source.load!
    end
    it "should update when the source is already cloned and update is true" do
      @source.stub!(:cloned?).and_return(true)
      @source.should_receive(:update!)
      @source.load!(true)
    end
  end

  describe "classification" do
    it "should treat file:// as public" do
      (source = Source.new(*@remote_1))
      [source.uri, source.name, source.type].should == [@remote_1.first, 'remote_1', :public]
    end
    it "should treat local paths as local" do
      (source = Source.new(@remote_1.first.gsub(/^file:\/\//, ''), @remote_1.last))
      [source.uri, source.name, source.type].should == [@remote_1.first.gsub(/^file:\/\//, ''), 'remote_1', :local]
    end
  end
end
