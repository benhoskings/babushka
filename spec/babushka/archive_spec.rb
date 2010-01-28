require 'spec_support'

describe Archive do
  it "should strip paths" do
    Archive.for('/path/to/archive.tgz').filename.should == 'archive.tgz'
    Archive.for('http://url.for/archive.tgz').filename.should == 'archive.tgz'
  end
  it "should detect supported archive types" do
    Archive.for('archive.tgz').should be_supported
    Archive.for('archive.tbz2').should be_supported
  end
  it "should raise an error on unsupported types" do
    L{
      Archive.for('archive.tgzz')
    }.should raise_error("Don't know how to extract archive.tgzz.")
  end
  it "should set the name" do
    Archive.for('archive.tar').name.should == 'archive'
    Archive.for('archive.tar.gz').name.should == 'archive'
  end
  it "should include a prefix on the name when supplied" do
    Archive.for('archive.tgz', :prefix => nil).name.should == 'archive'
    Archive.for('archive.tgz', :prefix => '').name.should == 'archive'
    Archive.for('archive.tgz', :prefix => 'prefix').name.should == 'prefix-archive'
  end
  it "should sanitise the prefix name" do
    Archive.for('archive.tgz', :prefix => 'silly  "dep" name!').name.should == 'silly_dep_name_-archive'
  end
  it "should fail to generate extract command for unknown files" do
    L{
      Archive.for('archive.tgzz').extract_command
    }.should raise_error ArchiveError, "Don't know how to extract archive.tgzz."
  end
  it "should generate the proper command to extract the archive" do
    {
      'tar' => "tar --strip-components=1 -xf '../archive.tar'",
      'tgz' => "tar --strip-components=1 -zxf '../archive.tgz'",
      'tbz2' => "tar --strip-components=1 -jxf '../archive.tbz2'",
      'zip' => "unzip -o -d 'archive' 'archive.zip'"
    }.each_pair {|ext,command|
      Archive.for("archive.#{ext}").extract_command.should == command
    }
  end
end
