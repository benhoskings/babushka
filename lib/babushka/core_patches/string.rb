class String
  # Return a DepRequirement that specifies the dep that should later be
  # called, and the arguments that should be passed. This allows requiring
  # deps with a less noisy syntax, and the lookup is lazy (it happens at the
  # point the dep is invoked, from its parent dep in Dep#run_requirements).
  #
  #   dep 'user has a password', :username do
  #     requires 'user exists'.with(username)
  #   end
  def with *args
    Babushka::DepRequirement.new(self, args)
  end

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

  # Extracts the value corresponding to the supplied key in an arbitrary,
  # multiline string. Most common config formats are handled. When there are
  # multiple matches, the first is returned. If there is no match, nil is
  # returned.
  #
  # See Array#val_for, and the cases in core_patches_spec.rb, for examples.
  def val_for key
    split("\n").val_for(key)
  end

  def / other
    (empty? ? other.p : (p / other))
  end

  # Create a VersionStr from this string.
  def to_version
    Babushka::VersionStr.new self
  end

  def to_utf8
    if !respond_to?(:encoding) # Skip on ruby-1.8.
      self
    elsif valid_encoding?
      encode("utf-8")
    else
      # Round-trip to force a conversion, stripping invalid chars.
      encode("utf-16be", :invalid => :replace, :replace => "?").encode("utf-8")
    end
  end

  def colorized?
    Babushka::LogHelpers.deprecated! "2014-03-29", :method_name => 'String#colorized?'
    self[/\e\[\d/]
  end

  # Wrap this string in ANSI color codes according to description. See the
  # Babushka::ANSI docs for details.
  def colourise description
    Babushka::ANSI.wrap(self, description)
  end
  alias_method :colorize, :colourise

  # As +colorize+, but modify this string in-place instead of returning a new one.
  def colorize! description = nil
    Babushka::LogHelpers.deprecated! "2014-03-29", :method_name => 'String#colorize!'
    replace colorize(description) unless description.nil?
  end

  # Return a new string with all color-related escape sequences removed.
  def decolorize
    Babushka::LogHelpers.deprecated! "2014-03-29", :method_name => 'String#decolorize'
    dup.decolorize!
  end

  # Remove all color-related escape sequences from this string in-place.
  def decolorize!
    Babushka::LogHelpers.deprecated! "2014-03-29", :method_name => 'String#decolorize!'
    gsub!(/\e\[\d+[;\d]*m/, '')
    self
  end
end
