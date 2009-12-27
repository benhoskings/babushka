require 'spec_support'

describe Archive do
  it "should strip paths" do
    Archive.new('/path/to/archive.tgz').filename.should == 'archive.tgz'
    Archive.new('http://url.for/archive.tgz').filename.should == 'archive.tgz'
  end
  it "should detect supported archive types" do
    Archive.new('archive.tgz').should be_supported
    Archive.new('archive.tbz2').should be_supported
    Archive.new('archive.tgzz').should_not be_supported
  end
  it "should set the name" do
    Archive.new('archive.tar').name.should == 'archive'
    Archive.new('archive.tar.gz').name.should == 'archive'
  end
  it "should fail to generate extract command for unknown files" do
    L{
      Archive.new('archive.tgzz').extract_command
    }.should raise_error ArchiveError, "Don't know how to extract archive.tgzz."
  end
  it "should generate the proper command to extract the archive" do
    {
      'tar' => 'tar -xf archive.tar',
      'tgz' => 'tar -zxf archive.tgz',
      'tbz2' => 'tar -jxf archive.tbz2'
    }.each_pair {|ext,command|
      Archive.new("archive.#{ext}").extract_command.should == command
    }
  end
end
