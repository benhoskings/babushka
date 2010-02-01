require 'spec_support'

def archive_path
  __FILE__.p.parent.parent / 'archives'
end

describe Archive do
  it "should detect file types" do
    Archive.type(archive_path / 'archive.zip').should == :zip
    Archive.type(archive_path / 'archive.tgz').should == :gzip
  end
  it "should detect supported archive types" do
    Archive.for(archive_path / 'archive.tgz').should be_supported
    Archive.for(archive_path / 'archive.tbz2').should be_supported
  end
  it "should raise an error on unsupported types" do
    L{
      Archive.for(archive_path / 'invalid_archive.tgz')
    }.should raise_error("Don't know how to extract invalid_archive.tgz.")
  end
  it "should set the name" do
    Archive.for(archive_path / 'archive.tar').name.should == 'archive'
    Archive.for(archive_path / 'archive.tar.gz').name.should == 'archive'
  end
  it "should include a prefix on the name when supplied" do
    Archive.for(archive_path / 'archive.tgz', :prefix => nil).name.should == 'archive'
    Archive.for(archive_path / 'archive.tgz', :prefix => '').name.should == 'archive'
    Archive.for(archive_path / 'archive.tgz', :prefix => 'prefix').name.should == 'prefix-archive'
  end
  it "should sanitise the prefix name" do
    Archive.for(archive_path / 'archive.tgz', :prefix => 'silly  "dep" name!').name.should == 'silly_dep_name_-archive'
  end
  it "should fail to generate extract command for unknown files" do
    L{
      Archive.for(archive_path / 'invalid_archive.tgz').extract_command
    }.should raise_error ArchiveError, "Don't know how to extract invalid_archive.tgz."
  end
  it "should generate the proper command to extract the archive" do
    {
      'tar' => "tar --strip-components=1 -xf '#{archive_path / 'archive.tar'}'",
      'tgz' => "tar --strip-components=1 -zxf '#{archive_path / 'archive.tgz'}'",
      'tbz2' => "tar --strip-components=1 -jxf '#{archive_path / 'archive.tbz2'}'",
      'zip' => "unzip -o '#{archive_path / 'archive.zip'}'"
    }.each_pair {|ext,command|
      Archive.for(archive_path / "archive.#{ext}").extract_command.should == command
    }
  end
end
