module Babushka
  class VersionStr

    include Comparable

    attr_reader :pieces

    def <=> other
      pieces <=> other.pieces
    end
    def initialize str
      @pieces = str.split('.').map(&:to_i)
    end
    def to_s
      pieces.join('.')
    end
    define_method "!=" do |other|
      !(self == other)
    end
    define_method "~>" do |other|
      (self >= other) && pieces.starts_with?(other.pieces[0..-2])
    end

  end
end
