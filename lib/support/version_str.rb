module Babushka
  class VersionStr

    include Comparable
    attr_reader :pieces, :operator
    GemVersionOperators = %w[= == != > < >= <= ~>].freeze

    def <=> other
      other = other.to_version if other.is_a? String
      max_length = [pieces.length, other.pieces.length].max
      (0...max_length).each do |index|
        result = compare_pieces pieces[index], other.pieces[index]
        return result unless result == 0
      end
      
      0 # no mismatches, consider it equal
    end
    
    def initialize str
      captures = str.strip.scan(/^((#{GemVersionOperators.join('|')})\s+)?(\d.*)/)
      raise "Bad input: '#{str}'" if captures.nil? || captures.first.nil?
      
      operator_with_space, @operator, version = captures.first
      
      if version.nil?
        raise "Bad input: '#{str}'"
      elsif !(@operator.nil? || GemVersionOperators.include?(@operator))
        raise "Bad operator: '#{@operator}'"
      else
        @pieces = version.strip.split(/[\.\-]/).collect { |piece|
          piece[/^\d+$/] ? piece.to_i : piece
        }
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
    
    private
    
    def compare_pieces(this, that)
      this = normalise_piece(this, that)
      that = normalise_piece(that, this)
      
      # String vs nil - nil wins
      return 1  if this.nil?
      return -1 if that.nil?
      
      if this.is_a?(String) && that.is_a?(String)
        compare_pieces this[/\d+/].to_i, that[/\d+/].to_i
      else
        this <=> that
      end
    end
    
    def normalise_piece(piece, reference)
      return piece unless piece.nil?
      
      # Only change nils to 0's if reference isn't an integer
      reference.is_a?(String) ? nil : 0
    end
  end
end
