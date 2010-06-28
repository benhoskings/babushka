require 'spec_support'

def archive_path
  __FILE__.p.parent.parent / 'archives'
end

describe Archive do
  it "should detect file types" do
    Archive.type(archive_path / 'archive.zip').should == :zip
    Archive.type(archive_path / 'archive.tgz').should == :gzip
  end
  it "should first attempt to detect type using file extension" do
    Archive.type(archive_path / 'really_a_gzip.zip').should == :zip
  end
  it "should attempt to detect type via when there is no extension" do
    Archive.type(archive_path / 'zip_without_extension').should == :zip
  end
  it "should detect supported archive types" do
    Archive.for(archive_path / 'archive.tgz').should be_supported
    Archive.for(archive_path / 'archive.tbz2').should be_supported
  end
  it "should raise an error on unsupported types" do
    L{
      Archive.for(archive_path / 'invalid_archive')
    }.should raise_error("Don't know how to extract invalid_archive.")
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
  it "should generate the proper command to extract the archive" do
    {
      'tar' => "tar -xf '#{archive_path / 'archive.tar'}'",
      'tgz' => "tar -zxf '#{archive_path / 'archive.tgz'}'",
      'tbz2' => "tar -jxf '#{archive_path / 'archive.tbz2'}'",
      'zip' => "unzip -o '#{archive_path / 'archive.zip'}'"
    }.each_pair {|ext,command|
      Archive.for(archive_path / "archive.#{ext}").extract_command.should == command
    }
  end
  it "should yield in the extracted dir" do
    Archive.for(archive_path / "archive.tar").extract {
      Dir.pwd.should == (tmp_prefix / 'archives/archive')
    }
  end
  it "should yield in the nested dir if there is one" do
    Archive.for(archive_path / "nested_archive.tar").extract {
      Dir.pwd.should == (tmp_prefix / 'archives/nested_archive/nested archive')
    }
  end
  it "should find a standard content dir as a nested dir" do
    Archive.for(archive_path / "test-0.3.1.tgz").extract {
      Dir.pwd.should == (tmp_prefix / 'archives/test-0.3.1/test-0.3.1')
      Dir.glob('*').should == ['content.txt']
    }
  end
  it "shouldn't descend into some dirs" do
    Archive.for(archive_path / "Blah.app.zip").extract {
      Dir.pwd.should == '~/.babushka/src/Blah.app'.p
      Dir.glob('**/*').should == ['Blah.app', 'Blah.app/content.txt']
    }
  end
end

describe Archive, '#content_subdir' do
  before {
    @archive = Archive.new('test.zip')
    @archive.stub!(:identity_dirs).and_return(
      %w[
        Blah.app
        Some.pkg
        Test.bundle
        Lolcode.tmbundle
        something.else
        and_a_random.file
      ]
    )
  }
  it "should reject dirs that shouldn't be descended" do
    @archive.content_subdir.should == 'something.else'
  end
end
