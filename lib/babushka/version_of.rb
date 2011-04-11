module Babushka
  def VersionOf first, *rest
    # Convert the arguments into a VersionOf. If a single string argument is
    # passed, try splitting it on space to separate name and version. Otherwise,
    # pass the arguments as-is, splatting if required.
    if rest.any?
      Babushka::VersionOf.new *[first].concat(rest)
    elsif first.is_a?(String)
      Babushka::VersionOf.new *first.split(' ', 2)
    elsif first.is_a?(Array)
      Babushka::VersionOf.new *first
    else
      Babushka::VersionOf.new first
    end
  end
  module_function :VersionOf

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

    def <=> other
      raise ArgumentError, "You can't compare the versions of two different things (#{name}, #{other.name})." unless name == other.name
      version <=> other.version
    end

    def matches? other
      if other.is_a? VersionStr
        version.nil? || other.send(version.operator, version)
      else
        matches? other.to_version
      end
    end

    def to_s joinery = '-'
      [name, version].compact * joinery
    end

    def inspect
      "#<VersionOf #{[name, version].compact.join(' | ')}>"
    end
  end
end
