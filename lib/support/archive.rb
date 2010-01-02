module Babushka
  class ArchiveError < StandardError
  end
  class Archive
    include Shell::Helpers

    ArchiveTypes = {
      '.tar' => '',
      '.tar.gz' => 'z',
      '.tgz' => 'z',
      '.tar.bz2' => 'j',
      '.tbz2' => 'j'
    }
    
    attr_reader :filename, :type, :name

    def initialize fn, opts = {}
      @filename = fn.to_s.p.basename.to_s
      @type = ArchiveTypes.keys.detect {|k| filename.ends_with? k }
      @name = [
        (opts[:prefix] || '').gsub(/[^a-z0-9\-_.]+/, '_'),
        filename.gsub(/#{type}$/, '')
      ].squash.join('-')
    end

    def supported?
      !type.nil?
    end

    def extract
      log_block "Extracting #{filename}" do
        shell("mkdir -p '#{name}'") and
        in_dir(name) { shell extract_command }
      end
    end

    def extract_command
      raise ArchiveError, "Don't know how to extract #{filename}." if type.nil?
      "tar --strip-components=1 -#{ArchiveTypes[type]}xf ../#{filename}"
    end
  end
end
