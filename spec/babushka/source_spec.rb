require 'spec_helper'
require 'source_support'

RSpec.describe Babushka::Source do
  before(:all) {
    @remote_1 = make_source_remote 'remote_1'
    @remote_2 = make_source_remote 'remote_2'
    @local_source_path = (Babushka::Source.source_prefix / 'local').tap(&:mkdir)
  }

  describe 'attributes' do
    it "should require either a path or a name" do
      expect { Babushka::Source.new(nil, nil) }.to raise_error(ArgumentError, "Sources with nil paths require a name (as the second argument).")
    end
    it "should store the path" do
      expect(Babushka::Source.new('/path/to/the-source').path).to eq('/path/to/the-source')
    end
    it "should set a default name" do
      expect(Babushka::Source.new('/path/to/the-source').name).to eq('the-source')
    end
    it "should accept a custom name" do
      expect(Babushka::Source.new('/path/to/the-source', 'custom-name').name).to eq('custom-name')
    end
    context "for nonexistent sources" do
      it "should set a default path" do
        expect(Babushka::Source.new(nil, 'the-source').path).to eq(Babushka::Source.source_prefix / 'the-source')
      end
      it "should not set a default uri" do
        expect(Babushka::Source.new(nil, 'the-source').uri).to be_nil
      end
      it "should accept a custom uri" do
        expect(Babushka::Source.new(nil, 'the-source', 'https://example.org/custom').uri).to eq('https://example.org/custom')
      end
      it "should use the supplied name when a custom uri is supplied" do
        expect(Babushka::Source.new(nil, 'the-source', 'https://example.org/custom').name).to eq('the-source')
      end
    end
    context "for existing sources" do
      it "should detect the uri" do
        source = Babushka::Source.new(@local_source_path)
        expect(source).to receive(:repo?).and_return(true)
        allow(Babushka::ShellHelpers).to receive(:shell).with('git config remote.origin.url', :cd => @local_source_path).and_return('https://github.com/test/babushka-deps.git')
        expect(source.uri).to eq('https://github.com/test/babushka-deps.git')
      end
      it "should not accept a custom uri" do
        expect {
          Babushka::Source.new(@local_source_path, 'custom-name', 'https://github.com/test/babushka-deps.git')
        }.to raise_error(ArgumentError, "The source URI can only be supplied if the source doesn't exist already.")
      end
    end
  end

  describe '#path' do
    it "should be a Fancypath" do
      expect(Babushka::Source.new(@local_source_path).path).to be_an_instance_of(Fancypath)
    end
  end

  describe '#name' do
    it "should be a String" do
      expect(Babushka::Source.new(@local_source_path).name).to be_an_instance_of(String)
    end
  end

  describe '#uri' do
    it "should be a String" do
      expect(Babushka::Source.new(nil, 'name', 'https://example.org/repo').uri).to be_an_instance_of(String)
    end
  end

  describe '#type' do
    context "when the source exists" do
      let(:source) { Babushka::Source.new(@local_source_path) }
      it "should be local when no uri is supplied" do
        expect(source.type).to eq(:local)
      end
      it "should be remote when the source is a repo with a remote uri" do
        allow(source).to receive(:repo?).and_return(true)
        expect(Babushka::ShellHelpers).to receive(:shell).with('git config remote.origin.url', :cd => @local_source_path).and_return('https://github.com/test/babushka-deps.git')
        expect(source.type).to eq(:remote)
      end
      it "should be local when the source is within a repo with a remote uri" do
        allow(source).to receive(:repo?).and_return(false)
        expect(source.type).to eq(:local)
      end
    end
    context "when the source doesn't exist" do
      it "should be local when no uri is supplied" do
        expect(Babushka::Source.new(Babushka::Source.source_prefix / 'nonexistent').type).to eq(:local)
      end
      it "should be remote when a uri is supplied" do
        expect(Babushka::Source.new(Babushka::Source.source_prefix / 'nonexistent', 'nonexistent', 'https://example.org/custom').type).to eq(:remote)
      end
    end
  end

  describe '#repo?' do
    let(:source) { Babushka::Source.new(@local_source_path) }
    it "should be true when the root of the source is a repo" do
      allow(source.repo).to receive(:root).and_return(source.path)
      expect(source).to be_repo
    end
    it "should be false when the source is within a repo" do
      allow(source.repo).to receive(:root).and_return(source.path.parent)
      expect(source).not_to be_repo
    end
    it "should be false when the source isn't within a repo" do
      allow(source.repo).to receive(:exists?).and_return(false)
      expect(source).not_to be_repo
    end
  end

  describe '#clear!' do
    let(:source) { Babushka::Source.new(@local_source_path) }
    it "should clear the deps and templates" do
      expect(source.deps).to receive(:clear!)
      expect(source.templates).to receive(:clear!)
      source.clear!
    end
  end

  describe "loading deps" do
    context "with a good source" do
      before {
        @source = Babushka::Source.new('spec/deps/good')
        @source.load!
      }
      it "should load deps from a file" do
        expect(@source.deps.names).to include('test dep 1')
        expect(@source.deps.names).to include('test dep 2')
      end
      it "should not have defined the deps" do
        dep = @source.deps.for('test dep 1')
        expect(dep.context).not_to be_loaded
      end
      it "should store the source the dep was loaded from" do
        expect(@source.deps.for('test dep 1').dep_source).to eq(@source)
      end
    end
    context "with a source with errors" do
      before {
        @source = Babushka::Source.new('spec/deps/bad')
      }
      it "should raise an error" do
        expect { @source.load! }.to raise_error(Babushka::SourceLoadError)
        expect(@source.deps.count).to eq(0)
      end
    end
  end

  describe "loading deps with parameters" do
    let(:source) { Babushka::Source.new('spec/deps/params').tap(&:load!) }
    let(:requires) { source.deps.for('top-level dep with params').context.define!.requires }
    it "should store the right number of requirements" do
      expect(requires.length).to eq(2)
    end
    it "should store the right kinds of objects" do
      expect(requires.map(&:class)).to eq([String, Babushka::DepRequirement])
    end
    it "should store string requirements properly" do
      expect(requires.first).to eq('a dep without params')
    end
    context "requirements" do
      let(:requirement) { requires.last }
      it "should store the name properly" do
        expect(requirement.name).to eq('another dep with params')
      end
      context "arguments" do
        let(:args) { requirement.args }
        it "should store parameters" do
          expect(args.map(&:class)).to eq([Babushka::Parameter])
        end
        it "should store the name properly" do
          expect(args.map(&:name)).to eq([:param])
        end
      end
    end
  end

  describe "defining deps" do
    before {
      @source = Babushka::Source.new('spec/deps/good')
      @source.load!
    }
    context "after loading" do
      before {
        @dep = @source.deps.for('test dep 1')
      }
      it "should not have defined the deps" do
        expect(@dep.context).not_to be_loaded
      end
    end
  end

  describe "equality" do
    it "should be equal when uri, name and type are the same" do
      expect(Babushka::Source.new('/path/to/the-source') == Babushka::Source.new('/path/to/the-source')).to be_truthy
    end
    it "shouldn't be equal when the name differs" do
      expect(Babushka::Source.new('/path/to/the-source') == Babushka::Source.new('/path/to/the-source', 'custom-name')).to be_falsey
    end
    it "shouldn't be equal when the uri differs" do
      expect(Babushka::Source.new('/path/to/the-source', 'name') == Babushka::Source.new('/path/to/the-source', 'name', 'https://example.org/custom')).to be_falsey
    end
  end

  describe Babushka::Source, ".for_path" do
    context "on a directory" do
      let(:source) { Babushka::Source.for_path(@local_source_path) }
      it "should find the source" do
        expect(source).to be_present
        expect([source.path, source.name]).to eq([@local_source_path, 'local'])
      end
      it "should cache the source" do
        expect(source.object_id).to eq(Babushka::Source.for_path(@local_source_path).object_id)
      end
    end
    context "on a git repo" do
      let(:source) { Babushka::Source.for_path(@remote_1.first) }
      before {
        Babushka::Source.new(*@remote_1).add! # Add the source so it exists
      }
      it "should work on a git repo" do
        expect(source).to be_present
        expect([source.path, source.name, source.uri]).to eq(@remote_1)
      end
      it "should cache the source" do
        expect(source.object_id).to eq(Babushka::Source.for_path(@remote_1.first).object_id)
      end
      after { source.path.rm }
    end
  end

  describe '.for_remote' do
    describe "special cases" do
      it "should return the common deps for 'common'" do
        source = Babushka::Source.for_remote('common')
        expect([source.path, source.name, source.uri]).to eq([(Babushka::Source.source_prefix / 'common').p, 'common', "https://github.com/benhoskings/common-babushka-deps.git"])
      end
    end
    it "should return a github URL in the standard form" do
      source = Babushka::Source.for_remote('benhoskings')
      expect([source.path, source.name, source.uri]).to eq([(Babushka::Source.source_prefix / 'benhoskings').p, 'benhoskings', "https://github.com/benhoskings/babushka-deps.git"])
    end
  end

  describe "finding" do
    before {
      @source = Babushka::Source.new('spec/deps/good')
      @source.load!
    }
    it "should find the specified dep" do
      expect(@source.find('test dep 1')).to be_an_instance_of(Babushka::Dep)
      expect(@source.deps.items.include?(@source.find('test dep 1'))).to be_truthy
    end
    it "should find the specified template" do
      expect(@source.find_template('test_meta_1')).to be_an_instance_of(Babushka::DepTemplate)
      expect(@source.templates.items.include?(@source.find_template('test_meta_1'))).to be_truthy
    end
  end

  describe Babushka::Source, "#present?" do
    context "for local repos" do
      it "should be true for existing paths" do
        expect(Babushka::Source.new('spec/deps/good')).to be_present
      end
      it "should be false for nonexistent paths" do
        expect(Babushka::Source.new('spec/deps/nonexistent')).not_to be_present
      end
    end
    context "for remote repos" do
      let(:source) { Babushka::Source.new(*@remote_1) }
      it "should be false" do
        expect(source).not_to be_present
      end
      context "after cloning" do
        it "should be true" do
          expect(source.tap(&:add!)).to be_present
        end
        after { source.path.rm }
      end
    end
  end

  describe '.present' do
    it "should include existing paths" do
      expect(Babushka::Source.present).to include(Babushka::Source.new(@local_source_path))
    end
    it "should not include sources with other paths" do
      expect(Babushka::Source.present).not_to include(Babushka::Source.new('spec/deps/good'))
    end
    it "should not include nonexistent paths" do
      expect(Babushka::Source.present).not_to include(Babushka::Source.new('spec/deps/nonexistent'))
    end

    context "for remote repos" do
      let(:source) { Babushka::Source.new(*@remote_1) }
      it "should be false" do
        expect(Babushka::Source.present).not_to include(source)
      end
      context "after cloning" do
        it "should be true" do
          source.add!
          expect(Babushka::Source.present).to include(source)
        end
        after { source.path.rm }
      end
    end
  end

  describe "cloning" do
    context "an unreadable source" do
      let(:source) { Babushka::Source.new(nil, 'unreadable', (tmp_prefix / "missing.git").to_s) }
      it "shouldn't work" do
        expect { source.add! }.to raise_error(Babushka::GitRepoError)
      end
    end

    context "a readable source" do
      context "with just a path" do
        let(:source) { Babushka::Source.new('/path/to/the-source') }
        it "should not add anything" do
          expect(Babushka::GitHelpers).not_to receive(:git)
          source.add!
        end
      end

      context "with just a name" do
        let(:source) { Babushka::Source.new(nil, 'source-name') }
        it "should not add anything" do
          expect(Babushka::GitHelpers).not_to receive(:git)
          source.add!
        end
      end

      context "with a uri" do
        let(:source) { Babushka::Source.new(*@remote_1) }
        it "shouldn't be present yet" do
          expect(source).not_to be_present
        end
        it "should clone the source" do
          expect(Babushka::GitHelpers).to receive(:git).with(source.uri, :to => (Babushka::Source.source_prefix / 'remote_1'), :log => true)
          source.add!
        end
        context "after adding" do
          before { source.add! }
          it "should be present now" do
            expect(source).to be_present
          end
          it "should be cloned into the source prefix" do
            expect(source.path).to eq(tmp_prefix / 'sources' / source.name)
          end
          after { source.path.rm }
        end
      end

      context "duplication" do
        before {
          allow(Babushka::GitHelpers).to receive(:git).and_return(true)
          allow(Babushka::Source).to receive(:present).and_return([source])
        }
        let(:source) { Babushka::Source.new(nil, 'the-source', 'https://example.org/the-source') }

        context "with the same name and URI" do
          let(:dup) { Babushka::Source.new(nil, 'the-source', 'https://example.org/the-source') }
          it "should work" do
            expect { dup.add! }.not_to raise_error
            expect(dup).to eq(source)
          end
        end
        context "with the same name and different URIs" do
          let(:dup) { Babushka::Source.new(nil, source.name, 'https://example.org/custom') }
          it "should fail" do
            expect { dup.add! }.to raise_error(Babushka::SourceError, "There is already a source called 'the-source' at #{source.path}.")
          end
        end
        context "with the same URI and different names" do
          let(:dup) { Babushka::Source.new(nil, 'custom-name', source.uri) }
          it "should fail" do
            expect { dup.add! }.to raise_error(Babushka::SourceError, "The remote #{source.uri} is already present on 'the-source', at #{source.path}.")
          end
        end
      end
    end
  end

  describe "updating" do
    before {
      @source = Babushka::Source.new(*@remote_2)
    }
    it "should update when the source isn't cloned" do
      expect(@source).to receive(:update!)
      @source.load!
    end
    it "should not update when the source is already present" do
      allow(@source).to receive(:repo?).and_return(true)
      expect(@source).not_to receive(:update!)
      @source.load!
    end
    it "should update when the source is already present and update is true" do
      allow(@source).to receive(:repo?).and_return(true)
      expect(@source).to receive(:update!)
      @source.load!(true)
    end
  end

end
