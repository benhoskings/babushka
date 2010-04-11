module Babushka
  class ArchiveError < StandardError
  end
  class Archive
    include Shell::Helpers
    extend Shell::Helpers

    def self.get_source url, &block
      filename = URI.unescape(url.to_s).p.basename
      if filename.to_s.blank?
        log_error "Not a valid URL to download: #{url}"
      else
        download_path = in_download_dir {|path|
          path / filename if download(url, filename)
        }
        if !download_path
          log_error "Failed to download #{url}."
        else
          in_build_dir { Archive.for(download_path).extract(&block) }
        end
      end
    end

    def self.download url, filename = url.to_s.p.basename
      if filename.p.exists? && !filename.p.empty?
        log_ok "Already downloaded #{filename}."
      else
        log_block "Downloading #{filename}" do
          shell %Q{curl -L -o "#{filename}.tmp" "#{url}"} and
          shell %Q{mv -f "#{filename}.tmp" "#{filename}"}
        end
      end
    end

    def self.type path
      TYPES.keys.detect {|key|
        shell("file '#{path}'")[TYPES[key][:file_match]]
      }
    end

    TYPES = {
      :tar => {:file_match => 'tar archive', :exts => %w[.tar]},
      :gzip => {:file_match => 'gzip compressed data', :exts => %w[.tgz .tar.gz]},
      :bzip2 => {:file_match => 'bzip2 compressed data', :exts => %w[.tbz2 .tar.bz2]},
      :zip => {:file_match => 'Zip archive data', :exts => %w[.zip]},
      :dmg => {:file_match => 'VAX COFF executable not stripped', :exts => %w[.dmg]}
    }

    attr_reader :path, :name

    def initialize path, opts = {}
      @path = path.p
      @name = [
        (opts[:prefix] || '').gsub(/[^a-z0-9\-_.]+/, '_'),
        TYPES[type][:exts].inject(filename) {|fn,t| fn.gsub(/#{t}$/, '') }
      ].squash.join('-')
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
      in_build_dir { process_extract &block }
    end

    def process_extract &block
      shell("mkdir -p '#{name}'") and
      in_dir(name) {
        unless log_shell("Extracting #{filename}", extract_command)
          log_error "Couldn't extract #{path}."
          log "(The file is probably corrupt - maybe the download was cancelled before it finished?)"
        else
          in_dir(content_subdir) {
            block.nil? or block.call(self)
          }
        end
      }
    end

    def content_subdir
      Dir.glob('*/').map {|dir| dir.chomp('/') }.select {|dir|
        dir.downcase.gsub(/[ -_\.]/, '') == name.downcase.gsub(/[ -_\.]/, '')
      }.reject {|dir|
        [/\.app$/].any? {|dont_descend| dir[dont_descend] }
      }.first
    end
  end

  class TarArchive < Archive
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

  class ZipArchive < Archive
    def extract_command
      "unzip -o '#{path}'"
    end
  end

  class DmgArchive < Archive
    def extract &block
      in_download_dir {
        output = log_shell "Attaching #{filename}", "hdiutil attach '#{filename.p.basename}'"
        unless output.nil?
          path = output.val_for(/^\/dev\/disk\d+s\d+\s+Apple_HFS\s+/)
          returning(in_dir(path) { block.call(self) }) do
            log_shell "Detaching #{filename}", "hdiutil detach '#{path}'"
          end
        end
      }
    end
  end
  
  class Archive
    CLASSES = {
      :tar => TarArchive,
      :gzip => TarArchive,
      :bzip2 => TarArchive,
      :zip => ZipArchive,
      :dmg => DmgArchive
    }

    def self.for path, opts = {}
      path = path.p
      filename = path.basename.to_s
      raise ArchiveError, "The archive #{filename} does not exist." unless path.exists?
      klass = CLASSES[type(path)]
      raise ArchiveError, "Don't know how to extract #{filename}." if klass.nil?
      klass.new(path, opts)
    end
  end
end
