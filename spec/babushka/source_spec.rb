require 'spec_helper'
require 'source_support'

describe Source do
  before(:all) {
    @remote_1 = make_source_remote 'remote_1'
    @remote_2 = make_source_remote 'remote_2'
    @local_source_path = (Source.source_prefix / 'local').tap(&:mkdir)
  }

  describe 'attributes' do
    it "should require either a path or a name" do
      expect { Source.new(nil, nil) }.to raise_error(ArgumentError, "Sources with nil paths require a name (as the second argument).")
    end
    it "should store the path" do
      Source.new('/path/to/the-source').path.should == '/path/to/the-source'
    end
    it "should set a default name" do
      Source.new('/path/to/the-source').name.should == 'the-source'
    end
    it "should accept a custom name" do
      Source.new('/path/to/the-source', 'custom-name').name.should == 'custom-name'
    end
    context "for nonexistent sources" do
      it "should set a default path" do
        Source.new(nil, 'the-source').path.should == Source.source_prefix / 'the-source'
      end
      it "should not set a default uri" do
        Source.new(nil, 'the-source').uri.should be_nil
      end
      it "should accept a custom uri" do
        Source.new(nil, 'the-source', 'https://example.org/custom').uri.should == 'https://example.org/custom'
      end
      it "should use the supplied name when a custom uri is supplied" do
        Source.new(nil, 'the-source', 'https://example.org/custom').name.should == 'the-source'
      end
    end
    context "for existing sources" do
      it "should detect the uri" do
        source = Source.new(@local_source_path)
        source.should_receive(:repo?).and_return(true)
        ShellHelpers.stub(:shell).with('git config remote.origin.url', :cd => @local_source_path).and_return('https://github.com/test/babushka-deps.git')
        source.uri.should == 'https://github.com/test/babushka-deps.git'
      end
      it "should not accept a custom uri" do
        expect {
          Source.new(@local_source_path, 'custom-name', 'https://github.com/test/babushka-deps.git')
        }.to raise_error(ArgumentError, "The source URI can only be supplied if the source doesn't exist already.")
      end
    end
  end

  describe '#type' do
    context "when the source exists" do
      let(:source) { Source.new(@local_source_path) }
      it "should be local when no uri is supplied" do
        source.type.should == :local
      end
      it "should be remote when the source is a repo with a remote uri" do
        source.stub(:repo?).and_return(true)
        ShellHelpers.should_receive(:shell).with('git config remote.origin.url', :cd => @local_source_path).and_return('https://github.com/test/babushka-deps.git')
        source.type.should == :remote
      end
      it "should be local when the source is within a repo with a remote uri" do
        source.stub(:repo?).and_return(false)
        source.type.should == :local
      end
    end
    context "when the source doesn't exist" do
      it "should be local when no uri is supplied" do
        Source.new(Source.source_prefix / 'nonexistent').type.should == :local
      end
      it "should be remote when a uri is supplied" do
        Source.new(Source.source_prefix / 'nonexistent', 'nonexistent', 'https://example.org/custom').type.should == :remote
      end
    end
  end

  describe '#repo?' do
    let(:source) { Source.new(@local_source_path) }
    it "should be true when the root of the source is a repo" do
      source.repo.stub(:root).and_return(source.path)
      source.should be_repo
    end
    it "should be false when the source is within a repo" do
      source.repo.stub(:root).and_return(source.path.parent)
      source.should_not be_repo
    end
    it "should be false when the source isn't within a repo" do
      source.repo.stub(:exists?).and_return(false)
      source.should_not be_repo
    end
  end

  describe "#cloned?" do
    it "should return false for local sources" do
      Source.new(@local_source_path).should_not be_cloned
    end
    context "for cloneable repos" do
      let(:source) { Source.new(*@remote_2) }
      it "should not be cloned" do
        source.should_not be_cloned
      end
      it "should be cloned after loading" do
        source.load!
        source.should be_cloned
      end
      after {
        source.path.rm
      }
    end
  end

  describe '#clear!' do
    let(:source) { Source.new(@local_source_path) }
    it "should clear the deps and templates" do
      source.deps.should_receive(:clear!)
      source.templates.should_receive(:clear!)
      source.clear!
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
      }
      it "should raise an error" do
        expect { @source.load! }.to raise_error(Babushka::SourceLoadError)
        @source.deps.count.should == 0
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
      (Source.new('/path/to/the-source') == Source.new('/path/to/the-source')).should be_true
    end
    it "shouldn't be equal when the name differs" do
      (Source.new('/path/to/the-source') == Source.new('/path/to/the-source', 'custom-name')).should be_false
    end
    it "shouldn't be equal when the uri differs" do
      (Source.new('/path/to/the-source', 'name') == Source.new('/path/to/the-source', 'name', 'https://example.org/custom')).should be_false
    end
  end

  describe Source, ".for_path" do
    context "on a directory" do
      let(:source) { Source.for_path(@local_source_path) }
      it "should find the source" do
        source.should be_present
        [source.path, source.name].should == [@local_source_path, 'local']
      end
      it "should cache the source" do
        source.object_id.should == Source.for_path(@local_source_path).object_id
      end
    end
    context "on a git repo" do
      let(:source) { Source.for_path(@remote_1.first) }
      before {
        Source.new(*@remote_1).add! # Add the source so it exists
      }
      it "should work on a git repo" do
        source.should be_present
        [source.path, source.name, source.uri].should == @remote_1
      end
      it "should cache the source" do
        source.object_id.should == Source.for_path(@remote_1.first).object_id
      end
      after { source.path.rm }
    end
  end

  describe '.for_remote' do
    describe "special cases" do
      it "should return the common deps for 'common'" do
        source = Source.for_remote('common')
        [source.path, source.name, source.uri].should == [(Source.source_prefix / 'common').p, 'common', "https://github.com/benhoskings/common-babushka-deps.git"]
      end
    end
    it "should return a github URL in the standard form" do
      source = Source.for_remote('benhoskings')
      [source.path, source.name, source.uri].should == [(Source.source_prefix / 'benhoskings').p, 'benhoskings', "https://github.com/benhoskings/babushka-deps.git"]
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
      @source.find_template('test_meta_1').should be_an_instance_of(DepTemplate)
      @source.templates.items.include?(@source.find_template('test_meta_1')).should be_true
    end
  end

  describe Source, "#present?" do
    context "for local repos" do
      it "should be true for existing paths" do
        Source.new('spec/deps/good').should be_present
      end
      it "should be false for nonexistent paths" do
        Source.new('spec/deps/nonexistent').should_not be_present
      end
    end
    context "for remote repos" do
      let(:source) { Source.new(*@remote_1) }
      it "should be false" do
        source.should_not be_present
      end
      context "after cloning" do
        it "should be true" do
          source.tap(&:add!).should be_present
        end
        after { source.path.rm }
      end
    end
  end

  describe '.present' do
    it "should include existing paths" do
      Source.present.should include(Source.new(@local_source_path))
    end
    it "should not include sources with other paths" do
      Source.present.should_not include(Source.new('spec/deps/good'))
    end
    it "should not include nonexistent paths" do
      Source.present.should_not include(Source.new('spec/deps/nonexistent'))
    end

    context "for remote repos" do
      let(:source) { Source.new(*@remote_1) }
      it "should be false" do
        Source.present.should_not include(source)
      end
      context "after cloning" do
        it "should be true" do
          source.add!
          Source.present.should include(source)
        end
        after { source.path.rm }
      end
    end
  end

  describe "cloning" do
    context "an unreadable source" do
      let(:source) { Source.new(nil, 'unreadable', (tmp_prefix / "missing.git").to_s) }
      it "shouldn't work" do
        expect { source.add! }.to raise_error(GitRepoError)
      end
    end

    context "a readable source" do
      context "with just a path" do
        let(:source) { Source.new('/path/to/the-source') }
        it "should not add anything" do
          GitHelpers.should_not_receive(:git)
          source.add!
        end
      end

      context "with just a name" do
        let(:source) { Source.new(nil, 'source-name') }
        it "should not add anything" do
          GitHelpers.should_not_receive(:git)
          source.add!
        end
      end

      context "with a uri" do
        let(:source) { Source.new(*@remote_1) }
        it "shouldn't be present yet" do
          source.should_not be_present
        end
        it "should clone the source" do
          GitHelpers.should_receive(:git).with(source.uri, :to => (Source.source_prefix / 'remote_1'), :log => true)
          source.add!
        end
        context "after adding" do
          before { source.add! }
          it "should be present now" do
            source.should be_present
          end
          it "should be cloned into the source prefix" do
            source.path.should == (tmp_prefix / 'sources' / source.name)
          end
          after { source.path.rm }
        end
      end

      context "duplication" do
        before {
          GitHelpers.stub(:git).and_return(true)
          Source.stub(:present).and_return([source])
        }
        let(:source) { Source.new(nil, 'the-source', 'https://example.org/the-source') }

        context "with the same name and URI" do
          let(:dup) { Source.new(nil, 'the-source', 'https://example.org/the-source') }
          it "should work" do
            L{ dup.add! }.should_not raise_error
            dup.should == source
          end
        end
        context "with the same name and different URIs" do
          let(:dup) { Source.new(nil, source.name, 'https://example.org/custom') }
          it "should fail" do
            expect { dup.add! }.to raise_error(SourceError, "There is already a source called 'the-source' at #{source.path}.")
          end
        end
        context "with the same URI and different names" do
          let(:dup) { Source.new(nil, 'custom-name', source.uri) }
          it "should fail" do
            expect { dup.add! }.to raise_error(SourceError, "The remote #{source.uri} is already present on 'the-source', at #{source.path}.")
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
      @source.stub(:cloned?).and_return(true)
      @source.should_not_receive(:update!)
      @source.load!
    end
    it "should update when the source is already cloned and update is true" do
      @source.stub(:cloned?).and_return(true)
      @source.should_receive(:update!)
      @source.load!(true)
    end
  end

end
