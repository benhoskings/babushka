require 'spec_helper'

def archive_path
  __FILE__.p.parent.parent / 'archives'
end

RSpec.describe Babushka::Asset do
  it "should detect file types" do
    expect(Babushka::Asset.type(archive_path / 'archive.zip')).to eq(:zip)
    expect(Babushka::Asset.type(archive_path / 'archive.tgz')).to eq(:gzip)
  end
  it "should first attempt to detect type using file extension" do
    expect(Babushka::Asset.type(archive_path / 'really_a_gzip.zip')).to eq(:zip)
  end
  it "should attempt to detect type via `file` when there is no extension" do
    expect(Babushka::Asset).to receive(:shell).with("file '#{archive_path / 'zip_without_extension'}'").and_return('Zip archive data')
    expect(Babushka::Asset.type(archive_path / 'zip_without_extension')).to eq(:zip)
  end
  it "should detect supported archive types" do
    expect(Babushka::Asset.for(archive_path / 'archive.tgz')).to be_supported
    expect(Babushka::Asset.for(archive_path / 'archive.tbz2')).to be_supported
  end
  it "should raise an error on unsupported types" do
    expect(Babushka::Asset).to receive(:shell).with("file '#{archive_path / 'invalid_archive'}'").and_return('ASCII text')
    expect(L{
      Babushka::Asset.for(archive_path / 'invalid_archive')
    }).to raise_error("Don't know how to extract invalid_archive.")
  end
  it "should set the name" do
    expect(Babushka::Asset.for(archive_path / 'archive.tar').name).to eq('archive')
    expect(Babushka::Asset.for(archive_path / 'archive.tar.gz').name).to eq('archive')
  end
  it "should generate the proper command to extract the archive" do
    {
      'tar' => "tar -xf '#{archive_path / 'archive.tar'}'",
      'tgz' => "tar -zxf '#{archive_path / 'archive.tgz'}'",
      'tbz2' => "tar -jxf '#{archive_path / 'archive.tbz2'}'",
      'zip' => "unzip -o '#{archive_path / 'archive.zip'}'"
    }.each_pair {|ext,command|
      expect(Babushka::Asset.for(archive_path / "archive.#{ext}").extract_command).to eq(command)
    }
  end
  it "should yield" do
    yielded = false
    Babushka::Asset.for(archive_path / "archive.tar").extract {
      yielded = true
    }
    expect(yielded).to be_truthy
  end
  it "should yield in the extracted dir" do
    Babushka::Asset.for(archive_path / "archive.tar").extract {
      expect(Dir.pwd).to eq(tmp_prefix / 'archives/archive')
    }
  end
  it "should yield in the nested dir if there is one" do
    Babushka::Asset.for(archive_path / "nested_archive.tar").extract {
      expect(Dir.pwd).to eq(tmp_prefix / 'archives/nested_archive/nested archive')
    }
  end
  it "should find a standard content dir as a nested dir" do
    Babushka::Asset.for(archive_path / "test-0.3.1.tgz").extract {
      expect(Dir.pwd).to eq(tmp_prefix / 'archives/test-0.3.1/test-0.3.1')
      expect(Dir.glob('*')).to eq(['content.txt'])
    }
  end
  it "shouldn't descend into some dirs" do
    Babushka::Asset.for(archive_path / "Blah.app.zip").extract {
      expect(Dir.pwd).to eq(tmp_prefix / 'archives/Blah.app')
      expect(Dir.glob('**/*')).to eq(['Blah.app', 'Blah.app/content.txt'])
    }
  end

  describe 'pre-build cleanup' do
    it "should remove the build dir before extracting" do
      (tmp_prefix / 'archives/archive/pre-existing-dir').mkdir
      Babushka::Asset.for(archive_path / "archive.tar").extract {
        expect((tmp_prefix / 'archives/archive').exists?).to be_truthy
        expect((tmp_prefix / 'archives/archive/pre-existing-dir').exists?).to be_falsey
        true
      }
    end
  end

  describe 'cleanup' do
    it "should remove the build dir on success" do
      Babushka::Asset.for(archive_path / "archive.tar").extract {
        expect((tmp_prefix / 'archives/archive').exists?).to be_truthy
        true
      }
      expect((tmp_prefix / 'archives/archive').exists?).to be_falsey
    end
    it "should not remove the build dir on failure" do
      Babushka::Asset.for(archive_path / "archive.tar").extract {
        expect((tmp_prefix / 'archives/archive').exists?).to be_truthy
        false
      }
      expect((tmp_prefix / 'archives/archive').exists?).to be_truthy
    end
  end

  describe '#content_subdir' do
    let(:resource) { Babushka::Asset.new('test.zip') }

    context "when there is just a single file inside the archive" do
      before {
        allow(Dir).to receive(:glob).and_return(['a dir'])
        expect(File).to receive(:directory?).with('a dir').and_return(false)
      }
      it "should choose it, whatever it's called" do
        expect(resource.content_subdir).to be_nil
      end
    end
    context "when there is just a single non-descendable dir inside the archive" do
      before {
        allow(Dir).to receive(:glob).and_return(['a dir.app'])
        expect(File).to receive(:directory?).with('a dir.app').and_return(true)
      }
      it "should choose it, whatever it's called" do
        expect(resource.content_subdir).to be_nil
      end
    end
    context "when there is just a single dir inside the archive" do
      before {
        allow(Dir).to receive(:glob).and_return(['a dir'])
        expect(File).to receive(:directory?).with('a dir').and_return(true)
      }
      it "should choose it, whatever it's called" do
        expect(resource.content_subdir).to eq('a dir')
      end
    end
    context "when there is more than one dir" do
      context "and none are named after the archive" do
        before {
          allow(Dir).to receive(:glob).and_return(['contents', 'another'])
        }
        it "should return nil (so the original extraction dir is used)" do
          expect(resource.content_subdir).to be_nil
        end
      end
      context "and one is named after the archive" do
        before {
          allow(Dir).to receive(:glob).and_return(['contents', 'test'])
        }
        it "should choose the directory named after the archive" do
          expect(resource.content_subdir).to eq('test')
        end
      end
    end
    context "when there are non-descendable dirs" do
      context "and none are named after the archive" do
        before {
          allow(Dir).to receive(:glob).and_return(['contents', 'LaunchBar.app', 'RSpec.tmbundle'])
        }
        it "should not choose the non-descendable dir" do
          expect(resource.content_subdir).to be_nil
        end
      end
      context "and one is named after the archive" do
        before {
          allow(Dir).to receive(:glob).and_return(['contents', 'test.app'])
        }
        it "should not choose the non-descendable dir" do
          expect(resource.content_subdir).to be_nil
        end
      end
      context "one is named after the archive, and a descendable dir is present too" do
        before {
          allow(Dir).to receive(:glob).and_return(['contents', 'test.app', 'test'])
        }
        it "should choose the descendable dir" do
          expect(resource.content_subdir).to eq('test')
        end
      end
    end
  end
end
