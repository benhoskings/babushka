module Babushka
  class ResourceError < StandardError
  end
  class Resource
    include LogHelpers
    extend LogHelpers
    include ShellHelpers
    extend ShellHelpers
    include PathHelpers
    extend PathHelpers

    def self.get url, &block
      filename = URI.unescape(url.to_s).p.basename
      if filename.to_s.blank?
        log_error "Not a valid URL to download: #{url}"
      else
        download_path = in_download_dir {|path|
          downloaded_file = download(url, filename)
          path / downloaded_file if downloaded_file
        }
        block.call download_path unless download_path.nil?
      end
    end

    def self.extract url, &block
      get url do |download_path|
        in_build_dir {
          Resource.for(download_path).extract(&block)
        }
      end
    end

    def self.download url, filename = url.to_s.p.basename
      if filename.p.exists? && !filename.p.empty?
        log_ok "Already downloaded #{filename}."
        filename
      elsif (result = shell(%Q{curl -I -X GET "#{url}"})).nil?
        log_error "Couldn't download #{url}: `curl` exited with non-zero status."
      else
        response_code = result.val_for(/HTTP\/1\.\d/) # not present for ftp://, etc.
        if response_code && response_code[/^[23]/].nil?
          log_error "Couldn't download #{url}: #{response_code}."
        elsif !(location = result.val_for('Location')).nil?
          log "Following redirect from #{url}"
          download URI.escape(location), location.p.basename
        else
          success = log_block "Downloading #{url}" do
            shell %Q{curl -# -o "#{filename}.tmp" "#{url}" && mv -f "#{filename}.tmp" "#{filename}"}, :progress => /[\d\.]+%/
          end
          filename if success
        end
      end
    end

    def self.detect_type_by_extension path
      TYPES.keys.detect {|key|
        TYPES[key][:exts].any? {|extension|
          path.has_extension? extension
        }
      }
    end
    
    def self.detect_type_by_contents path
      TYPES.keys.detect {|key|
        shell("file '#{path}'")[TYPES[key][:file_match]]
      }
    end

    def self.type path
      detect_type_by_extension(path) || detect_type_by_contents(path)
    end

    TYPES = {
      :deb => {:file_match => 'Debian binary package', :exts => %w[deb]},
      :pkg => {:file_match => 'xar archive', :exts => %w[pkg]},
      :tar => {:file_match => 'tar archive', :exts => %w[tar]},
      :gzip => {:file_match => 'gzip compressed data', :exts => %w[tgz tar.gz]},
      :bzip2 => {:file_match => 'bzip2 compressed data', :exts => %w[tbz2 tar.bz2]},
      :zip => {:file_match => 'Zip archive data', :exts => %w[zip]},
      :dmg => {:file_match => 'VAX COFF executable not stripped', :exts => %w[dmg]}
    }

    attr_reader :path, :name

    def initialize path, opts = {}
      @path = path.p
      @name = TYPES[type][:exts].inject(filename) {|fn,t| fn.gsub(/\.#{t}$/, '') }
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
      cd(archive_prefix, :create => true) { process_extract(&block) }
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

    def archive_prefix
      BuildPrefix
    end
  end

  class FileResource < Resource
    def extract &block
      in_download_dir {
        block.call(self)
      }
    end
  end

  class TarResource < Resource
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

  class ZipResource < Resource
    def extract_command
      "unzip -o '#{path}'"
    end
  end

  class DmgResource < Resource
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
  
  class Resource
    CLASSES = {
      :deb => FileResource,
      :pkg => FileResource,
      :tar => TarResource,
      :gzip => TarResource,
      :bzip2 => TarResource,
      :zip => ZipResource,
      :dmg => DmgResource
    }

    def self.for path, opts = {}
      path = path.p
      filename = path.basename.to_s
      raise ResourceError, "The archive #{filename} does not exist." unless path.exists?
      klass = CLASSES[type(path)]
      raise ResourceError, "Don't know how to extract #{filename}." if klass.nil?
      klass.new(path, opts)
    end
  end
end
