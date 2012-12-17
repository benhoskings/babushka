module Babushka
  class AssetError < StandardError
  end

  class Asset
    extend ShellHelpers
    include ShellHelpers
    include PathHelpers

    def self.detect_type_by_extension path
      ASSET_TYPES.keys.detect {|key|
        ASSET_TYPES[key][:exts].any? {|extension|
          path.has_extension? extension
        }
      }
    end

    def self.detect_type_by_contents path
      ASSET_TYPES.keys.detect {|key|
        shell("file '#{path}'")[ASSET_TYPES[key][:file_match]]
      }
    end

    def self.type path
      detect_type_by_extension(path) || detect_type_by_contents(path)
    end

    attr_reader :path, :name

    def initialize path, opts = {}
      @path = path.p
      @name = ASSET_TYPES[type][:exts].inject(filename) {|fn,t| fn.gsub(/\.#{t}$/, '') }
    end

    def filename
      path.basename.to_s
    end

    def type
      self.class.type path
    end

    def supported?
      !type.nil?
    end

    def extract &block
      cd(build_prefix, :create => true) { process_extract(&block) }
    end

    def process_extract &block
      shell("mkdir -p '#{name}'") and
      cd(name) {
        unless log_shell("Extracting #{filename}", extract_command)
          log_error "Couldn't extract #{path} - probably a bad download."
        else
          cd(content_subdir) {
            block.nil? or block.call(self)
          }
        end
      }.tap {|result|
        if result
          log_block "Cleaning up" do
            (build_prefix / name).p.rm
          end
        else
          log "The build artefacts are in #{build_prefix / name / content_subdir}."
        end
      }
    end

    def content_subdir
      identity_dirs.reject {|dir|
        %w[app pkg bundle tmbundle prefPane].map {|i|
          /\.#{i}$/
        }.any? {|dont_descend|
          dir[dont_descend]
        }
      }.first
    end

    def identity_dirs
      everything = Dir.glob('*')
      if everything.length == 1 && File.directory?(everything.first)
        everything
      else
        Dir.glob('*/').map {|dir| dir.chomp('/') }.select {|dir|
          dir.downcase.gsub(/[ \-_\.]/, '') == name.downcase.gsub(/[ \-_\.]/, '')
        }
      end
    end

    def build_prefix
      BuildPrefix
    end
  end

  class FileAsset < Asset
    def extract &block
      in_download_dir {
        block.call(self)
      }
    end
  end

  class TarAsset < Asset
    def extract_command
      "tar -#{extract_option(type)}xf '#{path}'"
    end

    def extract_option type
      {
        :tar => '',
        :gzip => 'z',
        :bzip2 => 'j'
      }[type]
    end
  end

  class ZipAsset < Asset
    def extract_command
      "unzip -o '#{path}'"
    end
  end

  class DmgAsset < Asset
    def extract &block
      in_download_dir {
        output = log_shell "Attaching #{filename}", "hdiutil attach '#{filename.p.basename}'"
        if output.nil?
          log_error "Couldn't mount #{filename.p}."
        elsif (path = mountpoint_for(output)).nil?
          raise "Couldn't find where `hdiutil` mounted #{filename.p}."
        else
          cd(path) {
            block.call(self)
          }.tap {
            log_shell "Detaching #{filename}", "hdiutil detach '#{path}'"
          }
        end
      }
    end

    def mountpoint_for output
      output.scan(/\s+(\/Volumes\/[^\n]+)/).flatten.first
    end
  end

  class Asset
    ASSET_TYPES = {
      :deb =>   {:exts => %w[deb],          :class => FileAsset, :file_match => 'Debian binary package'},
      :pkg =>   {:exts => %w[pkg],          :class => FileAsset, :file_match => 'xar archive'},
      :tar =>   {:exts => %w[tar],          :class => TarAsset,  :file_match => 'tar archive'},
      :gzip =>  {:exts => %w[tgz tar.gz],   :class => TarAsset,  :file_match => 'gzip compressed data'},
      :bzip2 => {:exts => %w[tbz2 tar.bz2], :class => TarAsset,  :file_match => 'bzip2 compressed data'},
      :zip =>   {:exts => %w[zip],          :class => ZipAsset,  :file_match => 'Zip archive data'},
      :dmg =>   {:exts => %w[dmg],          :class => DmgAsset,  :file_match => 'VAX COFF executable not stripped'}
    }

    def self.for path, opts = {}
      path = path.p
      filename = path.basename.to_s
      raise AssetError, "The archive #{filename} does not exist." unless path.exists?
      if (asset_type = ASSET_TYPES[type(path)]).nil?
        raise AssetError, "Don't know how to extract #{filename}."
      else
        asset_type[:class].new(path, opts)
      end
    end
  end

end
