class String
  # Returns true iff +other+ appears exactly at the start of +self+.
  def starts_with? other
    self[0, other.length] == other
  end

  # Returns true iff +other+ appears exactly at the end of +self+.
  def ends_with? other
    self[-other.length, other.length] == other
  end

  # Return a duplicate of +self+, with +other+ prepended to it if it doesn't already start with +other+.
  def start_with other
    starts_with?(other) ? self : other + self
  end

  # Return a duplicate of +self+, with +other+ appended to it if it doesn't already end with +other+.
  def end_with other
    ends_with?(other) ? self : self + other
  end

  def val_for key
    split("\n").grep(
      key.is_a?(Regexp) ? key : /(^|^[^\w]*\s+)#{Regexp.escape(key)}\b/
    ).map {|l|
      l.sub(/^[^\w]*\s+/, '').
        sub(key.is_a?(Regexp) ? key : /^#{Regexp.escape(key)}\b\s*[:=]?/, '').
        sub(/[;,]\s*$/, '').
        strip
    }.first || ''
  end
  def / other
    (empty? ? other.p : (p / other))
  end

  def camelize
    # From activesupport/lib/active_support/inflector.rb:178
    gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end

  def words
    split(/[^a-z0-9_.-]+/i)
  end

  # This is defined separately, and then aliased into place if required, so we
  # can run specs against it no matter which ruby we're running against.
  def local_lines
    strip.split(/\n+/)
  end
  alias_method :lines, :local_lines unless "".respond_to?(:lines)

  def to_version
    Babushka::VersionStr.new self
  end

  def colorize description = '', start_at = nil
    if start_at.nil? || (cut_point = index(start_at)).nil?
      Colorizer.colorize self, description
    else
      self[0...cut_point] + Colorizer.colorize(self[cut_point..-1], description)
    end
  end

  def colorize! description = '', start_at = nil
    replace colorize(description, start_at) unless description.blank?
  end

  def decolorize
    dup.decolorize!
  end

  def decolorize!
    gsub! /\e\[\d+[;\d]*m/, ''
    self
  end

  def similarity_to other, threshold = nil
    Babushka::Levenshtein.distance self, other, threshold
  end
end