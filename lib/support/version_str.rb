module Babushka
  class VersionStr

    include Comparable
    attr_reader :pieces, :operator
    GemVersionOperators = %w[= == != > < >= <= ~>].freeze

    def <=> other
      pieces <=> other.pieces unless pieces.nil? || other.pieces.nil?
    end
    def initialize str
      captures = str.strip.scan(/^(#{GemVersionOperators.join('|')})?\s*([0-9.]+)/)
      if captures.nil? || captures.first.nil? || captures.first.last.nil?
        raise "Bad input: '#{str}'"
      elsif !(captures.first.first.nil? || GemVersionOperators.include?(captures.first.first))
        raise "Bad operator: '#{captures.first.first}'"
      else
        @pieces = captures.first.last.split('.').map(&:to_i)
        @operator = captures.first.first
        @operator = '==' if @operator == '='
      end
    end
    def to_s
      [
        operator_str,
        pieces.join('.')
      ].compact.join(' ')
    end
    def match_operator
      operator || '=='
    end
    def operator_str
      operator.gsub('==', '=') unless operator.nil?
    end
    define_method "!=" do |other|
      !(self == other)
    end
    define_method "~>" do |other|
      (self >= other) && pieces.starts_with?(other.pieces[0..-2])
    end

  end
end
