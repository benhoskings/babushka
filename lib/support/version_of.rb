module Babushka
  class VersionOf
    module Helpers
      def ver name, version = nil
        VersionOf.new name, version
      end
    end

    attr_accessor :name, :version

    def initialize name, version = nil
      @name = name.respond_to?(:name) ? name.name : name
      @version = if version.nil?
        name.version if name.respond_to?(:version)
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

    def <=> other
      raise ArgumentError, "You can't compare the versions of two different things." unless name == other.name
      version <=> other.version
    end

    def matches? other
      if other.is_a? VersionStr
        version.nil? || other.send(version.match_operator, version)
      else
        matches? other.to_version
      end
    end

    def to_s
      [name, version].compact * '-'
    end

  end
end
