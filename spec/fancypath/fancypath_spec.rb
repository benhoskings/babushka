require 'fancypath_support'

describe Fancypath do
  before do
    TMP_DIR.rmtree if TMP_DIR.exist?
    TMP_DIR.mkpath
    @file = TMP_DIR.to_fancypath/'testfile'
    @dir = TMP_DIR.to_fancypath/'testdir'
  end
  after { TMP_DIR.rmtree }

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
      @file.length.should == File.join(TMP_DIR, 'testfile').length
      @dir.length.should == File.join(TMP_DIR, 'testdir').length
    end
  end

  describe '#join', 'aliased to #/' do
    it('returns a Fancypath') { (@dir/'somefile').class.should == Fancypath }
    it('joins paths') { (@dir/'somefile').to_s.should =~ /\/somefile$/ }
    it('joins absolute paths') { (@dir/'/somefile').to_s.should == File.join(@dir, 'somefile') }
  end

  describe '#parent' do
    it('returns parent') { @file.parent.should == TMP_DIR.to_fancypath }
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
      @mkdir = Fancypath(TMP_DIR/'nested/mkdir')
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
      TMP_DIR.glob('**/*').should =~ ['tmp/fancypath/testdir'.p.to_s, 'tmp/fancypath/testfile'.p.to_s]
    end
    it "should glob with no args" do
      (TMP_DIR / '**/*').glob.should =~ ['tmp/fancypath/testdir'.p.to_s, 'tmp/fancypath/testfile'.p.to_s]
    end
    it "should be case insensitive" do
      TMP_DIR.glob('**/TEST*').should =~ ['tmp/fancypath/testdir'.p.to_s, 'tmp/fancypath/testfile'.p.to_s]
    end
  end

  describe '#write' do
    it('returns self') { @file.write('').should == @file }
    it('returns a Fancypath') { @file.write('').should be_instance_of(Fancypath) }
    it('writes contents to file') { @file.write('test').read.should == 'test' }
  end

  describe '#copy' do
    before { @file.touch }
    it('returns a Fancypath') { @file.copy(TMP_DIR/'foo').should be_instance_of(Fancypath) }
    it('creates a new file') { @file.copy(TMP_DIR/'foo').should exist }
    it('keeps the original') { @file.copy(TMP_DIR/'foo'); @file.should exist }
    it('copies the contents') { @file.copy(TMP_DIR/'foo').read.should == @file.read }
  end

  describe '#copy on a directory' do
    before {
      @dir.mkdir
      (@dir / 'testfile').touch
    }
    it('returns a Fancypath') { @dir.copy(TMP_DIR/'foo').should be_instance_of(Fancypath) }
    it('creates a new dir with a file in it') {
      @dir.copy(TMP_DIR/'foo')
      (TMP_DIR/'foo').should exist
      (TMP_DIR/'foo/testfile').should exist
    }
    it('keeps the original') { @dir.copy(TMP_DIR/'foo'); @dir.should exist }
    it('copies the contents') { @dir.copy(TMP_DIR/'foo'); (TMP_DIR/'foo/testfile').read.should == (@dir/'testfile').read }
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
      dest = TMP_DIR/'newfile'
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

  describe '#select' do
    example 'with symbol' do
      @dir.create_dir
      %W(a.jpg b.jpg c.gif).each { |f| (@dir/f).touch }
      @dir.select(:jpg).should == [@dir/'a.jpg', @dir/'b.jpg']
    end

    example 'with glob' do
      @dir.create_dir
      %W(a.jpg b.jpg c.gif).each { |f| (@dir/f).touch }
      @dir.select("*.jpg").should == [@dir/'a.jpg', @dir/'b.jpg']
    end

    example 'with regex' do
      @dir.create_dir
      %W(a.jpg b.jpg c.gif 1.jpg).each { |f| (@dir/f).touch }
      @dir.select(/[^\d]\.(jpg|gif)$/).should =~ [@dir/'a.jpg', @dir/'b.jpg', @dir/'c.gif']
    end

    example 'with multiple args' do
      @dir.create_dir
      %W(a.jpg b.jpg c.gif).each { |f| (@dir/f).touch }
      @dir.select(:jpg, '*.gif').should == [@dir/'a.jpg', @dir/'b.jpg', @dir/'c.gif']
    end

    # todo: with block
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
