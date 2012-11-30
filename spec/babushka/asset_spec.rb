require 'spec_helper'

def archive_path
  __FILE__.p.parent.parent / 'archives'
end

describe Babushka::Asset do
  it "should detect file types" do
    Asset.type(archive_path / 'archive.zip').should == :zip
    Asset.type(archive_path / 'archive.tgz').should == :gzip
  end
  it "should first attempt to detect type using file extension" do
    Asset.type(archive_path / 'really_a_gzip.zip').should == :zip
  end
  it "should attempt to detect type via `file` when there is no extension" do
    Asset.should_receive(:shell).with("file '#{archive_path / 'zip_without_extension'}'").any_number_of_times.and_return('Zip archive data')
    Asset.type(archive_path / 'zip_without_extension').should == :zip
  end
  it "should detect supported archive types" do
    Asset.for(archive_path / 'archive.tgz').should be_supported
    Asset.for(archive_path / 'archive.tbz2').should be_supported
  end
  it "should raise an error on unsupported types" do
    Asset.should_receive(:shell).with("file '#{archive_path / 'invalid_archive'}'").any_number_of_times.and_return('ASCII text')
    L{
      Asset.for(archive_path / 'invalid_archive')
    }.should raise_error("Don't know how to extract invalid_archive.")
  end
  it "should set the name" do
    Asset.for(archive_path / 'archive.tar').name.should == 'archive'
    Asset.for(archive_path / 'archive.tar.gz').name.should == 'archive'
  end
  it "should generate the proper command to extract the archive" do
    {
      'tar' => "tar -xf '#{archive_path / 'archive.tar'}'",
      'tgz' => "tar -zxf '#{archive_path / 'archive.tgz'}'",
      'tbz2' => "tar -jxf '#{archive_path / 'archive.tbz2'}'",
      'zip' => "unzip -o '#{archive_path / 'archive.zip'}'"
    }.each_pair {|ext,command|
      Asset.for(archive_path / "archive.#{ext}").extract_command.should == command
    }
  end
  it "should yield" do
    yielded = false
    Asset.for(archive_path / "archive.tar").extract {
      yielded = true
    }
    yielded.should be_true
  end
  it "should yield in the extracted dir" do
    Asset.for(archive_path / "archive.tar").extract {
      Dir.pwd.should == (tmp_prefix / 'archives/archive')
    }
  end
  it "should yield in the nested dir if there is one" do
    Asset.for(archive_path / "nested_archive.tar").extract {
      Dir.pwd.should == (tmp_prefix / 'archives/nested_archive/nested archive')
    }
  end
  it "should find a standard content dir as a nested dir" do
    Asset.for(archive_path / "test-0.3.1.tgz").extract {
      Dir.pwd.should == (tmp_prefix / 'archives/test-0.3.1/test-0.3.1')
      Dir.glob('*').should == ['content.txt']
    }
  end
  it "shouldn't descend into some dirs" do
    Asset.for(archive_path / "Blah.app.zip").extract {
      Dir.pwd.should == (tmp_prefix / 'archives/Blah.app')
      Dir.glob('**/*').should == ['Blah.app', 'Blah.app/content.txt']
    }
  end

  describe '#content_subdir' do
    let(:resource) { Asset.new('test.zip') }

    context "when there is just a single file inside the archive" do
      before {
        Dir.stub!(:glob).and_return(['a dir'])
        File.should_receive(:directory?).with('a dir').and_return(false)
      }
      it "should choose it, whatever it's called" do
        resource.content_subdir.should be_nil
      end
    end
    context "when there is just a single non-descendable dir inside the archive" do
      before {
        Dir.stub!(:glob).and_return(['a dir.app'])
        File.should_receive(:directory?).with('a dir.app').and_return(true)
      }
      it "should choose it, whatever it's called" do
        resource.content_subdir.should be_nil
      end
    end
    context "when there is just a single dir inside the archive" do
      before {
        Dir.stub!(:glob).and_return(['a dir'])
        File.should_receive(:directory?).with('a dir').and_return(true)
      }
      it "should choose it, whatever it's called" do
        resource.content_subdir.should == 'a dir'
      end
    end
    context "when there is more than one dir" do
      context "and none are named after the archive" do
        before {
          Dir.stub!(:glob).and_return(['contents', 'another'])
        }
        it "should return nil (so the original extraction dir is used)" do
          resource.content_subdir.should be_nil
        end
      end
      context "and one is named after the archive" do
        before {
          Dir.stub!(:glob).and_return(['contents', 'test'])
        }
        it "should choose the directory named after the archive" do
          resource.content_subdir.should == 'test'
        end
      end
    end
    context "when there are non-descendable dirs" do
      context "and none are named after the archive" do
        before {
          Dir.stub!(:glob).and_return(['contents', 'LaunchBar.app', 'RSpec.tmbundle'])
        }
        it "should not choose the non-descendable dir" do
          resource.content_subdir.should be_nil
        end
      end
      context "and one is named after the archive" do
        before {
          Dir.stub!(:glob).and_return(['contents', 'test.app'])
        }
        it "should not choose the non-descendable dir" do
          resource.content_subdir.should be_nil
        end
      end
      context "one is named after the archive, and a descendable dir is present too" do
        before {
          Dir.stub!(:glob).and_return(['contents', 'test.app', 'test'])
        }
        it "should choose the descendable dir" do
          resource.content_subdir.should == 'test'
        end
      end
    end
  end
end
