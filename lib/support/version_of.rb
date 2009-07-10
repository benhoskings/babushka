module Babushka
  class VersionOf

    attr_accessor :name, :version

    def initialize name, version = nil
      @name = name
      @version = if version.nil?
        nil
      elsif version.is_a? VersionStr
        version
      else
        version.to_version
      end
    end

    def == other
      if other.is_a? VersionOf
        name == other.name &&
        version == other.version
      else
        to_s == other.to_s
      end
    end

    def to_s
      [name, version].compact * '-'
    end

  end
end
