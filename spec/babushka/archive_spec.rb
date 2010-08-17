require 'spec_helper'

def archive_path
  __FILE__.p.parent.parent / 'archives'
end

describe Resource do
  it "should detect file types" do
    Resource.type(archive_path / 'archive.zip').should == :zip
    Resource.type(archive_path / 'archive.tgz').should == :gzip
  end
  it "should first attempt to detect type using file extension" do
    Resource.type(archive_path / 'really_a_gzip.zip').should == :zip
  end
  it "should attempt to detect type via when there is no extension" do
    Resource.type(archive_path / 'zip_without_extension').should == :zip
  end
  it "should detect supported archive types" do
    Resource.for(archive_path / 'archive.tgz').should be_supported
    Resource.for(archive_path / 'archive.tbz2').should be_supported
  end
  it "should raise an error on unsupported types" do
    L{
      Resource.for(archive_path / 'invalid_archive')
    }.should raise_error("Don't know how to extract invalid_archive.")
  end
  it "should set the name" do
    Resource.for(archive_path / 'archive.tar').name.should == 'archive'
    Resource.for(archive_path / 'archive.tar.gz').name.should == 'archive'
  end
  it "should include a prefix on the name when supplied" do
    Resource.for(archive_path / 'archive.tgz', :prefix => nil).name.should == 'archive'
    Resource.for(archive_path / 'archive.tgz', :prefix => '').name.should == 'archive'
    Resource.for(archive_path / 'archive.tgz', :prefix => 'prefix').name.should == 'prefix-archive'
  end
  it "should sanitise the prefix name" do
    Resource.for(archive_path / 'archive.tgz', :prefix => 'silly  "dep" name!').name.should == 'silly_dep_name_-archive'
  end
  it "should generate the proper command to extract the archive" do
    {
      'tar' => "tar -xf '#{archive_path / 'archive.tar'}'",
      'tgz' => "tar -zxf '#{archive_path / 'archive.tgz'}'",
      'tbz2' => "tar -jxf '#{archive_path / 'archive.tbz2'}'",
      'zip' => "unzip -o '#{archive_path / 'archive.zip'}'"
    }.each_pair {|ext,command|
      Resource.for(archive_path / "archive.#{ext}").extract_command.should == command
    }
  end
  it "should yield in the extracted dir" do
    Resource.for(archive_path / "archive.tar").extract {
      Dir.pwd.should == (tmp_prefix / 'archives/archive')
    }
  end
  it "should yield in the nested dir if there is one" do
    Resource.for(archive_path / "nested_archive.tar").extract {
      Dir.pwd.should == (tmp_prefix / 'archives/nested_archive/nested archive')
    }
  end
  it "should find a standard content dir as a nested dir" do
    Resource.for(archive_path / "test-0.3.1.tgz").extract {
      Dir.pwd.should == (tmp_prefix / 'archives/test-0.3.1/test-0.3.1')
      Dir.glob('*').should == ['content.txt']
    }
  end
  it "shouldn't descend into some dirs" do
    Resource.for(archive_path / "Blah.app.zip").extract {
      Dir.pwd.should == (tmp_prefix / 'archives/Blah.app')
      Dir.glob('**/*').should == ['Blah.app', 'Blah.app/content.txt']
    }
  end
end

describe Resource, '#content_subdir' do
  before {
    @resource = Resource.new('test.zip')
    @resource.stub!(:identity_dirs).and_return(
      %w[
        Blah.app
        Some.pkg
        Test.bundle
        Lolcode.tmbundle
        OMGSettings.prefPane
        something.else
        and_a_random.file
      ]
    )
  }
  it "should reject dirs that shouldn't be descended" do
    @resource.content_subdir.should == 'something.else'
  end
end
