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

    def initialize fn
      @filename = fn.to_s.p.basename.to_s
      @type = ArchiveTypes.keys.detect {|k| filename.ends_with? k }
      @name = filename.gsub /#{type}$/, ''
    end

    def supported?
      !type.nil?
    end

    def extract
      log_shell "Extracting #{filename}", extract_command
    end

    def extract_command
      raise ArchiveError, "Don't know how to extract #{filename}." if type.nil?
      "tar -#{ArchiveTypes[type]}xf #{filename}"
    end
  end
end
