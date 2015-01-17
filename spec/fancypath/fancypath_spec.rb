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
      Fancypath('test').should == Fancypath('test')
      Fancypath('test').should_not == Fancypath('test2')
    end
    it "should compare properly with strings" do
      Fancypath('test').should == 'test'
      Fancypath('test').should_not == 'test2'
    end
    it "should compare in reverse with strings" do
      'test'.should == Fancypath('test')
      'test2'.should_not == Fancypath('test')
    end
  end

  describe '#length' do
    it "should calculate the length" do
      @file.length.should == @file.to_s.length
      @file.length.should == File.join(tmp_dir, 'testfile').length
      @dir.length.should == File.join(tmp_dir, 'testdir').length
    end
  end

  describe '#hypothetically_writable?' do
    it "initial conditions" do
      @file.should_not be_exists
      @dir.should_not be_exists
      @dir.parent.should be_exists
      @dir.parent.should be_writable
    end
    it "returns true for writable paths" do
      @file.stub(:writable_real?).and_return(true)

      @file.should be_hypothetically_writable
    end
    it "returns false for existing, nonwritable paths" do
      @file.stub(:exists?).and_return(true)
      @file.stub(:writable_real?).and_return(false)

      @file.should_not be_hypothetically_writable
    end
    it "returns true for nonexistent paths when the parent is writable" do
      @file.stub(:parent).and_return(@dir)
      @dir.stub(:writable_real?).and_return(true)
      dir_parent = @dir.parent
      dir_parent.stub(:hypothetically_writable?).and_return(false)
      @dir.stub(:parent).and_return(dir_parent)

      subfile = @file / 'subfile'
      subfile.stub(:parent).and_return(@file)

      @file.should be_hypothetically_writable
      subfile.should be_hypothetically_writable
    end
    it "returns false for nonexistent paths when the parent isn't writable" do
      @file.stub(:parent).and_return(@dir)
      @dir.stub(:exists?).and_return(true)
      @dir.stub(:writable_real?).and_return(false)

      subfile = @file / 'subfile'
      subfile.stub(:parent).and_return(@file)

      @file.should_not be_hypothetically_writable
      subfile.should_not be_hypothetically_writable
    end
    it "works for the root" do
      @root = '/'.p
      @root.stub(:writable_real?).and_return(false)
      @root.should_not be_hypothetically_writable
    end
  end

  describe '#join', 'aliased to #/' do
    it('returns a Fancypath') { (@dir/'somefile').class.should == Fancypath }
    it('joins paths') { (@dir/'somefile').to_s.should =~ /\/somefile$/ }
    it('joins absolute paths') { (@dir/'/somefile').to_s.should == File.join(@dir, 'somefile') }
  end

  describe '#parent' do
    it('returns parent') { @file.parent.should == tmp_dir.to_fancypath }
    it('returns Fancypath') { @file.parent.should be_instance_of(Fancypath) }
  end

  describe '#touch', 'file does not exist' do
    it('returns self') { @file.touch.should == @file }
    it('returns a Fancypath') { @file.touch.should be_instance_of(Fancypath) }
    it('creates file') { @file.touch.should be_file }
  end

  describe '#create', 'dir does not exist' do
    it('returns self') { @dir.create.should == @dir }
    it('returns a Fancypath') { @dir.create.should be_instance_of(Fancypath) }
    it('creates directory') { @dir.create.should be_directory }
  end

  describe '#remove' do
    it('returns self') { @file.remove.should == @file }
    it('returns a Fancypath') { @file.remove.should be_instance_of(Fancypath) }
    it('removes file') { @file.touch.remove.should_not exist }
    it('removes directory') { @dir.create.remove.should_not exist }
  end

  describe "#grep" do
    before {
      @file.write("some\ncontent\ncontentedness")
    }
    it("returns nil when the file doesn't exist") {
      (@dir / 'missing').grep(/test/).should be_nil
    }
    it('returns nil on no match') {
      @file.grep(/test/).should be_nil
    }
    it('returns the matches with string parameter') {
      @file.grep("content").should == ['content']
    }
    it('returns the matches with regexp parameter') {
      @file.grep(/cont/).should == ['content', 'contentedness']
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
      @file.yaml.should == {'guise' => {'seriously' => 'guise'}}
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
    it('returns self for non-symlinks') { @file.readlink.should == @file }
    it('returns the target for relative symlinks') { @relative_link.readlink.should == @file }
    it('returns the target for absolute symlinks') { @absolute_link.readlink.should == '/bin/bash' }
  end

  describe '#mkdir' do
    before {
      @mkdir = Fancypath(tmp_dir/'nested/mkdir')
    }
    it "should create directories" do
      @mkdir.exists?.should == false
      @mkdir.mkdir
      @mkdir.exists?.should == true
    end
  end

  describe '#glob' do
    before {
      @dir.create_dir
      @file.touch
    }
    it "should glob" do
      tmp_dir.glob('**/*').should =~ [(tmp_prefix/'fancypath/testdir'), (tmp_prefix/'fancypath/testfile')].map(&:to_s)
    end
    it "should glob with no args" do
      (tmp_dir / '**/*').glob.should =~ [(tmp_prefix/'fancypath/testdir'), (tmp_prefix/'fancypath/testfile')].map(&:to_s)
    end
    it "should be case insensitive" do
      tmp_dir.glob('**/TEST*').should =~ [(tmp_prefix/'fancypath/testdir'), (tmp_prefix/'fancypath/testfile')].map(&:to_s)
    end
  end

  describe '#write' do
    it('returns self') { @file.write('').should == @file }
    it('returns a Fancypath') { @file.write('').should be_instance_of(Fancypath) }
    it('writes contents to file') { @file.write('test').read.should == 'test' }
  end

  describe '#puts' do
    it('returns self') { @file.write('').should == @file }
    it('appends the line to the file') {
      @file.puts('test1').puts('test2').read.should == "test1\ntest2\n"
    }
    it('does not add a trailing newline when one is already present') {
      @file.puts("test1\n").read.should == "test1\n"
    }
  end

  describe '#copy' do
    before { @file.touch }
    it('returns a Fancypath') { @file.copy(tmp_dir/'foo').should be_instance_of(Fancypath) }
    it('creates a new file') { @file.copy(tmp_dir/'foo').should exist }
    it('keeps the original') { @file.copy(tmp_dir/'foo'); @file.should exist }
    it('copies the contents') { @file.copy(tmp_dir/'foo').read.should == @file.read }
  end

  describe '#copy on a directory' do
    before {
      @dir.mkdir
      (@dir / 'testfile').touch
    }
    it('returns a Fancypath') { @dir.copy(tmp_dir/'foo').should be_instance_of(Fancypath) }
    it('creates a new dir with a file in it') {
      @dir.copy(tmp_dir/'foo')
      (tmp_dir/'foo').should exist
      (tmp_dir/'foo/testfile').should exist
    }
    it('keeps the original') { @dir.copy(tmp_dir/'foo'); @dir.should exist }
    it('copies the contents') { @dir.copy(tmp_dir/'foo'); (tmp_dir/'foo/testfile').read.should == (@dir/'testfile').read }
  end

  describe '#set_extension' do
    example "file without extension" do
      Fancypath('/tmp/foo').set_extension('rb').should == Fancypath('/tmp/foo.rb')
    end
    example "single extension" do
      Fancypath('/tmp/foo.py').set_extension('rb').should == Fancypath('/tmp/foo.rb')
    end
    example "multi extension" do
      Fancypath('/tmp/foo.py.z').set_extension('rb').should == Fancypath('/tmp/foo.py.rb')
    end
  end

  describe '#move' do
    example "destination has the file contents, source does not exist" do
      @file.write('foo')
      dest = tmp_dir/'newfile'
      @file.move( dest )
      @file.should_not exist
      dest.read.should == 'foo'
    end
  end

  describe '#has_extension?' do
    example do
      Fancypath('/tmp/foo.bar').has_extension?('bar').should be_true
    end
    example do
      Fancypath('/tmp/foo.bar').has_extension?('foo').should be_false
    end
  end

  describe '#empty?' do
    example 'with empty file' do
      @file.touch
      @file.empty?.should be_true
    end
    example 'with non-empty file' do
      @file.write 'foo'
      @file.empty?.should be_false
    end
    example 'with empty dir' do
      @dir.create_dir
      @dir.empty?.should be_true
    end
    example 'with non-empty dir' do
      @dir.create_dir
      (@dir/'foo').touch
      @dir.empty?.should be_false
    end
  end
end #/Fancypath

describe "String#to_fancypath" do
  it('returns a Fancypath') { 'test'.to_fancypath.should be_instance_of(Fancypath) }
end

describe "Pathname#to_fancypath" do
  it('returns a Fancypath') { Fancypath.new('/').to_fancypath.should be_instance_of(Fancypath) }
end
