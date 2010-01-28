module Babushka
  class ArchiveError < StandardError
  end
  class Archive
    include Shell::Helpers
    extend Shell::Helpers

    def self.get_source url, &block
      filename = url.to_s.p.basename
      if filename.to_s.blank?
        log_error "Not a valid URL to download: #{url}"
      else
        archive = Archive.for filename
        in_build_dir {
          if !download(url, filename)
            log_error "Failed to download #{url}."
          else
            returning archive.extract(&block) do |result|
              unless result
                log_error "Couldn't extract #{filename.p}."
                log "(The file is probably corrupt - maybe the download was cancelled before it finished?)"
              end
            end
          end
        }
      end
    end

    def self.download url, filename = url.to_s.p.basename
      if filename.p.exists?
        log_ok "Already downloaded #{filename}."
      else
        log_shell "Downloading #{filename}", %Q{curl -L -o "#{filename}" "#{url}"}
      end
    end

    attr_reader :filename, :type, :name

    def initialize fn, opts = {}
      @filename = fn.to_s.p.basename.to_s
      @type = types.keys.detect {|k| filename.ends_with? k }
      @name = [
        (opts[:prefix] || '').gsub(/[^a-z0-9\-_.]+/, '_'),
        filename.gsub(/#{type}$/, '')
      ].squash.join('-')
    end

    def supported?
      !type.nil?
    end

    def types
      TYPES[self.class]
    end
  end

  class TarArchive < Archive
    def extract &block
      shell("mkdir -p '#{name}'") and
      in_dir(name) {
        log_shell("Extracting #{filename}", extract_command) and
        block.call(self)
      }
    end
    def extract_command
      "tar --strip-components=1 -#{types[type]}xf '../#{filename}'"
    end
  end

  class ZipArchive < Archive
    def extract &block
      log_shell("Extracting #{filename}", extract_command) and
      in_dir(name) { block.call(self) }
    end
    def extract_command
      "unzip -o -d '#{name}' '#{filename}'"
    end
  end

  class DmgArchive < Archive
    def extract &block
      output = log_shell "Mounting #{filename}", "hdiutil attach '#{filename.p.basename}'"
      unless output.nil?
        path = output.val_for(/^\/dev\/disk\d+s\d+\s+Apple_HFS\s+/)
        returning(in_dir(path) { block.call(self) }) do
          log_shell "Unmounting #{filename}", "hdiutil detach '#{path}'"
        end
      end
    end
  end
  
  class Archive
    TYPES = {
      TarArchive => {
        '.tar' => '',
        '.tar.gz' => 'z',
        '.tgz' => 'z',
        '.tar.bz2' => 'j',
        '.tbz2' => 'j'
      },
      ZipArchive => {
        '.zip' => ''
      },
      DmgArchive => {
        '.dmg' => ''
      }
    }

    def self.for fn, opts = {}
      filename = fn.to_s.p.basename.to_s
      klass = TYPES.keys.detect {|k| TYPES[k].keys.detect {|k| filename.ends_with? k } }
      raise ArchiveError, "Don't know how to extract #{filename}." if klass.nil?
      klass.new(fn, opts)
    end
  end
end
