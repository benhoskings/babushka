module Babushka
  class VersionStr

    include Comparable
    attr_reader :pieces, :operator
    GemVersionOperators = %w[= != > < >= <= ~>].freeze

    def <=> other
      pieces <=> other.pieces
    end
    def initialize str
      captures = str.scan(/^(#{GemVersionOperators.join('|')})?\s*([0-9.]+)$/)
      unless captures.nil? || captures.first.nil? || captures.first.last.nil?
        @pieces = captures.first.last.split('.').map(&:to_i)
        @operator = captures.first.first
      end
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
