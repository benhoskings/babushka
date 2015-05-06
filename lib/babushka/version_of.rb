module Babushka

  def VersionOf first, *rest
    # Convert the arguments into a VersionOf. If a single string argument is
    # passed, try splitting it on space to separate name and version. Otherwise,
    # pass the arguments as-is, splatting if required.
    if rest.any?
      Babushka::VersionOf.new(*[first].concat(rest))
    elsif first.is_a?(String)
      name, version = first.split(' ', 2)
      if version && VersionStr.parseable_version?(version)
        Babushka::VersionOf.new(name, version)
      else
        Babushka::VersionOf.new(first)
      end
    elsif first.is_a?(Array)
      Babushka::VersionOf.new(*first)
    else
      Babushka::VersionOf.new(first)
    end
  end

  module_function :VersionOf

  class VersionOf
    module Helpers
      def VersionOf first, *rest
        # TODO: decide on the form for this and deprecate the others.
        Babushka.VersionOf(first, *rest)
      end
      module_function :VersionOf
    end

    attr_accessor :name, :version

    def initialize name, version = nil
      @name = name.is_a?(VersionOf) ? name.name : name
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
      return nil unless name == other.name
      version <=> other.version
    end

    def matches? other
      if other.is_a? VersionStr
        version.nil? || other.send(version.operator, version)
      else
        matches? other.to_version
      end
    end

    def to_s
      # == joins with a dash to produce versions like 'rack-1.4.1'; anything
      # else joins with space like 'rack >= 1.4'.
      [name, version].compact * (exact? ? '-' : ' ')
    end

    def exact?
      !version.nil? && version.operator == '=='
    end

    def inspect
      "#<VersionOf #{name}#{", v#{version}" unless version.nil?}>"
    end
  end
end
