class Array
  # Returns true iff +other+ appears exactly at the start of +self+.
  def starts_with? first, *rest
    other = first.is_a?(Array) ? first : [first].concat(rest)
    self[0, other.length] == other
  end

  # Returns true iff +other+ appears exactly at the end of +self+.
  def ends_with? first, *rest
    other = first.is_a?(Array) ? first : [first].concat(rest)
    self[-other.length, other.length] == other
  end

  # Like #detect, but return the result of the block instead of the element.
  def pick &block
    value = nil
    detect {|i| value = yield(i) }
    value
  end

  # Extracts the value from the item in the array that corresponds to the
  # supplied key. Most common config formats are handled. When there are
  # multiple matches, the first is returned. If there is no match, nil is
  # returned.
  #
  # Some quick examples:
  #   ['key: value'].val_for('key')  #=> 'value'
  #   ['key = value'].val_for('key')  #=> 'value'
  #
  # Leading and trailing whitespace is ignored. Keys starting with non-word
  # characters are valid, and leading non-word chars are ignored.
  #   ['*key: value'].val_for('*key') #=> 'value'
  #   ['*key: value'].val_for('key')  #=> nil
  #   ['* key: value'].val_for('key') #=> 'value'
  #
  # Spaces within the key and value are handled properly too.
  #   ['key with spaces: value'].val_for('key with spaces') #=> 'value'
  #   ['key: value with spaces'].val_for('key') #=> 'value with spaces'
  #
  # For a full list of the supported input, check the test cases in
  # core_patches_spec.rb.
  #
  def val_for key
    grep(
      # The key we're after, maybe preceded by non-word chars and spaces, and
      # followed either by a word/non-word boundary or whitespace.
      key.is_a?(Regexp) ? key : /(^|^[^\w]*\s+)#{Regexp.escape(key)}(\b|(?=\s))/
    ).map {|l|
      l.sub(/^[^\w]*\s+/, '').
        sub(key.is_a?(Regexp) ? key : /^#{Regexp.escape(key)}(\b|(?=\s))\s*[:=]?/, '').
        sub(/[;,]\s*$/, '').
        strip
    }.first
  end

  # This is defined separately, and then aliased into place if required, so we
  # can run specs against it no matter which ruby we're running against.
  def local_group_by &block
    inject({}) {|hsh,i|
      (hsh[yield(i)] ||= []).push i
      hsh
    }
  end
  alias_method :group_by, :local_group_by unless [].respond_to?(:group_by)

  # Return two arrays, the first being the portion of this array preceding the
  # first element for which the block returs true, and the second being the
  # remainder (or +nil+ if the block didn't return true for any elements).
  def cut &block
    Babushka::LogHelpers.deprecated! '2017-09-01'
    if (cut_at = index {|i| yield i }).nil?
      [self, nil]
    else
      [self[0...cut_at], self[cut_at..-1]]
    end
  end
  # Return two arrays in the same manner as +cut+, but check for element
  # equality against +value+ to find the point at which to cut the array.
  def cut_at value
    Babushka::LogHelpers.deprecated! '2017-09-01'
    cut {|i| i == value }
  end
  # Return a new array containing every element from this array for which
  # the block returns true.
  def extract &block
    Babushka::LogHelpers.deprecated! '2017-09-01', instead: '#select'
    dup.extract!(&block)
  end
  # Like +extract+, but remove the extracted values in-place before
  # returning them.
  def extract! &block
    Babushka::LogHelpers.deprecated! '2017-09-01', instead: '#select!'
    dup.inject [] do |extracted,i|
      extracted << delete(i) if yield i
      extracted
    end
  end
  # Return a new array containing all the elements from this array that
  # are neither +#nil?+ nor +#blank?+.
  def squash
    Babushka::LogHelpers.deprecated! '2017-09-01'
    dup.squash!
  end
  # Like +squash+, but remove the +#nil?+ and +#blank?+ entries in-place.
  def squash!
    Babushka::LogHelpers.deprecated! '2017-09-01'
    delete_if(&:blank?)
  end

  # Return a new array containing the elements that match +pattern+, with
  # +pattern+ removed (or replaced via Array#sub, if +replacement+ is
  # supplied).
  #
  # This is useful for selecting items from a list based on some label,
  # removing the label at the same time. A good example is finding the current
  # git branch. Given this repository:
  #   $ git branch
  #     master
  #   * next
  #     topic
  # You can use +#collapse+ to retrieve the current branch like this:
  #   shell('git branch').split("\n").collapse(/\* /) #=> ["next"]
  def collapse pattern, replacement = ''
    grep(pattern).map {|i| i.sub pattern, replacement }
  end

  # Return a new array by converting each element in this array to a VersionOf.
  def versions
    # TODO: deprecate
    map {|i| Babushka::VersionOf::Helpers.VersionOf i }
  end

  # Return a string describing this array as an English list. The final two
  # elements are separated with 'and', and all the other elements are separated
  # with commas.
  #
  #   %w[John Paul Ringo George].to_list #=> "John, Paul, Ringo and George"
  #
  # A custom conjugation can be specified by passing +:conj+; if present, it
  # will be used instead of 'and'.
  #
  #   %[rain hail shine].to_list(:conj => 'or') #=> "rain, hail or shine"
  #
  # To add an oxford comma before the conjugation, pass +:oxford => true+.
  #
  #   %w[hook line sinker].to_list(:oxford => true) #=> "hook, line, and sinker"
  #
  def to_list(opts = {})
    # TODO: deprecate
    items = map(&:to_s)
    [
      items[0..-2].compact.join(', '),
      items.last
    ].reject(&:blank?).join("#{',' if opts[:oxford]} #{opts[:conj] || 'and'} ")
  end

  # If the final element of the array is a +Hash+, it's removed from this array
  # and returned. Otherwise, an empty hash is returned.
  def extract_options!
    # TODO: deprecate
    last.is_a?(::Hash) ? pop : {}
  end

  # As above, without modifying the receiving object.
  def extract_options
    # TODO: deprecate
    dup.extract_options!
  end

  def similar_to string
    Babushka::LogHelpers.deprecated! '2017-09-01', instead: 'Babushka::Spell.for(str, choices: arr)'
    Babushka::Spell.for(string, choices: self)
  end
end
