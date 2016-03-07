require 'spec_helper'
require 'fancypath_support'

describe Fancypath do
  let(:tmp_dir) { tmp_prefix / 'fancypath' }
  before do
    tmp_dir.rmtree if tmp_dir.exist?
    tmp_dir.mkpath
    @file = tmp_dir.to_fancypath/'testfile'
    @dir = tmp_dir.to_fancypath/'testdir'
  end
  after { tmp_dir.rmtree }

  describe '#==' do
    it "should compare properly with other fancypaths" do
      expect(Fancypath('test')).to eq(Fancypath('test'))
      expect(Fancypath('test')).not_to eq(Fancypath('test2'))
    end
    it "should compare properly with strings" do
      expect(Fancypath('test')).to eq('test')
      expect(Fancypath('test')).not_to eq('test2')
    end
    it "should compare in reverse with strings" do
      expect('test').to eq(Fancypath('test'))
      expect('test2').not_to eq(Fancypath('test'))
    end
  end

  describe '#length' do
    it "should calculate the length" do
      expect(@file.length).to eq(@file.to_s.length)
      expect(@file.length).to eq(File.join(tmp_dir, 'testfile').length)
      expect(@dir.length).to eq(File.join(tmp_dir, 'testdir').length)
    end
  end

  describe '#hypothetically_writable?' do
    it "initial conditions" do
      expect(@file).not_to be_exists
      expect(@dir).not_to be_exists
      expect(@dir.parent).to be_exists
      expect(@dir.parent).to be_writable
    end
    it "returns true for writable paths" do
      allow(@file).to receive(:writable_real?).and_return(true)

      expect(@file).to be_hypothetically_writable
    end
    it "returns false for existing, nonwritable paths" do
      allow(@file).to receive(:exists?).and_return(true)
      allow(@file).to receive(:writable_real?).and_return(false)

      expect(@file).not_to be_hypothetically_writable
    end
    it "returns true for nonexistent paths when the parent is writable" do
      allow(@file).to receive(:parent).and_return(@dir)
      allow(@dir).to receive(:writable_real?).and_return(true)
      dir_parent = @dir.parent
      allow(dir_parent).to receive(:hypothetically_writable?).and_return(false)
      allow(@dir).to receive(:parent).and_return(dir_parent)

      subfile = @file / 'subfile'
      allow(subfile).to receive(:parent).and_return(@file)

      expect(@file).to be_hypothetically_writable
      expect(subfile).to be_hypothetically_writable
    end
    it "returns false for nonexistent paths when the parent isn't writable" do
      allow(@file).to receive(:parent).and_return(@dir)
      allow(@dir).to receive(:exists?).and_return(true)
      allow(@dir).to receive(:writable_real?).and_return(false)

      subfile = @file / 'subfile'
      allow(subfile).to receive(:parent).and_return(@file)

      expect(@file).not_to be_hypothetically_writable
      expect(subfile).not_to be_hypothetically_writable
    end
    it "works for the root" do
      @root = '/'.p
      allow(@root).to receive(:writable_real?).and_return(false)
      expect(@root).not_to be_hypothetically_writable
    end
  end

  describe '#join', 'aliased to #/' do
    it('returns a Fancypath') { expect((@dir/'somefile').class).to eq(Fancypath) }
    it('joins paths') { expect((@dir/'somefile').to_s).to match(/\/somefile$/) }
    it('joins absolute paths') { expect((@dir/'/somefile').to_s).to eq(File.join(@dir, 'somefile')) }
  end

  describe '#parent' do
    it('returns parent') { expect(@file.parent).to eq(tmp_dir.to_fancypath) }
    it('returns Fancypath') { expect(@file.parent).to be_instance_of(Fancypath) }
  end

  describe '#touch', 'file does not exist' do
    it('returns self') { expect(@file.touch).to eq(@file) }
    it('returns a Fancypath') { expect(@file.touch).to be_instance_of(Fancypath) }
    it('creates file') { expect(@file.touch).to be_file }
  end

  describe '#create', 'dir does not exist' do
    it('returns self') { expect(@dir.create).to eq(@dir) }
    it('returns a Fancypath') { expect(@dir.create).to be_instance_of(Fancypath) }
    it('creates directory') { expect(@dir.create).to be_directory }
  end

  describe '#remove' do
    it('returns self') { expect(@file.remove).to eq(@file) }
    it('returns a Fancypath') { expect(@file.remove).to be_instance_of(Fancypath) }
    it('removes file') { expect(@file.touch.remove).not_to exist }
    it('removes directory') { expect(@dir.create.remove).not_to exist }
  end

  describe "#grep" do
    before {
      @file.write("some\ncontent\ncontentedness")
    }
    it("returns nil when the file doesn't exist") {
      expect((@dir / 'missing').grep(/test/)).to be_nil
    }
    it('returns nil on no match') {
      expect(@file.grep(/test/)).to be_nil
    }
    it('returns the matches with string parameter') {
      expect(@file.grep("content")).to eq(['content'])
    }
    it('returns the matches with regexp parameter') {
      expect(@file.grep(/cont/)).to eq(['content', 'contentedness'])
    }
  end

  describe "#yaml" do
    before {
      @file.write("
        guise:
          seriously: guise
      ")
    }
    it('returns the file contents as yaml') {
      expect(@file.yaml).to eq({'guise' => {'seriously' => 'guise'}})
    }
  end

  describe '#readlink' do
    before {
      @file.touch
      @dir.mkdir
      Dir.chdir @dir do
        `ln -s ../testfile testlink_relative`
        `ln -s /bin/bash testlink_absolute`
      end
      @relative_link = @dir/'testlink_relative'
      @absolute_link = @dir/'testlink_absolute'
    }
    it('returns self for non-symlinks') { expect(@file.readlink).to eq(@file) }
    it('returns the target for relative symlinks') { expect(@relative_link.readlink).to eq(@file) }
    it('returns the target for absolute symlinks') { expect(@absolute_link.readlink).to eq('/bin/bash') }
  end

  describe '#mkdir' do
    before {
      @mkdir = Fancypath(tmp_dir/'nested/mkdir')
    }
    it "should create directories" do
      expect(@mkdir.exists?).to eq(false)
      @mkdir.mkdir
      expect(@mkdir.exists?).to eq(true)
    end
  end

  describe '#glob' do
    before {
      @dir.create_dir
      @file.touch
    }
    it "should glob" do
      expect(tmp_dir.glob('**/*')).to match_array([(tmp_prefix/'fancypath/testdir'), (tmp_prefix/'fancypath/testfile')].map(&:to_s))
    end
    it "should glob with no args" do
      expect((tmp_dir / '**/*').glob).to match_array([(tmp_prefix/'fancypath/testdir'), (tmp_prefix/'fancypath/testfile')].map(&:to_s))
    end
    it "should be case insensitive" do
      expect(tmp_dir.glob('**/TEST*')).to match_array([(tmp_prefix/'fancypath/testdir'), (tmp_prefix/'fancypath/testfile')].map(&:to_s))
    end
  end

  describe '#write' do
    it('returns self') { expect(@file.write('')).to eq(@file) }
    it('returns a Fancypath') { expect(@file.write('')).to be_instance_of(Fancypath) }
    it('writes contents to file') { expect(@file.write('test').read).to eq('test') }
  end

  describe '#puts' do
    it('returns self') { expect(@file.write('')).to eq(@file) }
    it('appends the line to the file') {
      expect(@file.puts('test1').puts('test2').read).to eq("test1\ntest2\n")
    }
    it('does not add a trailing newline when one is already present') {
      expect(@file.puts("test1\n").read).to eq("test1\n")
    }
  end

  describe '#copy' do
    before { @file.touch }
    it('returns a Fancypath') { expect(@file.copy(tmp_dir/'foo')).to be_instance_of(Fancypath) }
    it('creates a new file') { expect(@file.copy(tmp_dir/'foo')).to exist }
    it('keeps the original') { @file.copy(tmp_dir/'foo'); expect(@file).to exist }
    it('copies the contents') { expect(@file.copy(tmp_dir/'foo').read).to eq(@file.read) }
  end

  describe '#copy on a directory' do
    before {
      @dir.mkdir
      (@dir / 'testfile').touch
    }
    it('returns a Fancypath') { expect(@dir.copy(tmp_dir/'foo')).to be_instance_of(Fancypath) }
    it('creates a new dir with a file in it') {
      @dir.copy(tmp_dir/'foo')
      expect(tmp_dir/'foo').to exist
      expect(tmp_dir/'foo/testfile').to exist
    }
    it('keeps the original') { @dir.copy(tmp_dir/'foo'); expect(@dir).to exist }
    it('copies the contents') { @dir.copy(tmp_dir/'foo'); expect((tmp_dir/'foo/testfile').read).to eq((@dir/'testfile').read) }
  end

  describe '#set_extension' do
    example "file without extension" do
      expect(Fancypath('/tmp/foo').set_extension('rb')).to eq(Fancypath('/tmp/foo.rb'))
    end
    example "single extension" do
      expect(Fancypath('/tmp/foo.py').set_extension('rb')).to eq(Fancypath('/tmp/foo.rb'))
    end
    example "multi extension" do
      expect(Fancypath('/tmp/foo.py.z').set_extension('rb')).to eq(Fancypath('/tmp/foo.py.rb'))
    end
  end

  describe '#move' do
    example "destination has the file contents, source does not exist" do
      @file.write('foo')
      dest = tmp_dir/'newfile'
      @file.move( dest )
      expect(@file).not_to exist
      expect(dest.read).to eq('foo')
    end
  end

  describe '#has_extension?' do
    example do
      expect(Fancypath('/tmp/foo.bar').has_extension?('bar')).to be_truthy
    end
    example do
      expect(Fancypath('/tmp/foo.bar').has_extension?('foo')).to be_falsey
    end
  end

  describe '#empty?' do
    example 'with empty file' do
      @file.touch
      expect(@file.empty?).to be_truthy
    end
    example 'with non-empty file' do
      @file.write 'foo'
      expect(@file.empty?).to be_falsey
    end
    example 'with empty dir' do
      @dir.create_dir
      expect(@dir.empty?).to be_truthy
    end
    example 'with non-empty dir' do
      @dir.create_dir
      (@dir/'foo').touch
      expect(@dir.empty?).to be_falsey
    end
  end
end #/Fancypath

describe "String#to_fancypath" do
  it('returns a Fancypath') { expect('test'.to_fancypath).to be_instance_of(Fancypath) }
end

describe "Pathname#to_fancypath" do
  it('returns a Fancypath') { expect(Fancypath.new('/').to_fancypath).to be_instance_of(Fancypath) }
end
