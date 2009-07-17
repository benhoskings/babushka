module Babushka
  module VersionHelpers
    def self.included base # :nodoc:
      base.send :include, HelperMethods
    end

    module HelperMethods
      def ver name, version = nil; VersionOf.new name, version end
    end
  end

  class VersionOf

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

    def matches? other
      if other.is_a? VersionStr
        version.nil? || other.send(version.operator || :==, version)
      else
        matches? other.to_version
      end
    end

    def to_s
      [name, version].compact * '-'
    end

  end
end
