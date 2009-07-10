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

    def to_s
      [name, version].compact * '-'
    end

  end
end
