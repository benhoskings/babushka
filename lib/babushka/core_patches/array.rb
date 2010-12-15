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

  # This is defined separately, and then aliased into place if required, so we
  # can run specs against it no matter which ruby we're running against.
  def local_group_by &block
    inject(Hash.new {|hsh,k| hsh[k] = [] }) {|hsh,i|
      hsh[yield(i)].push i
      hsh
    }
  end
  alias_method :group_by, :local_group_by unless [].respond_to?(:group_by)

  # Return two arrays, the first being the portion of this array up to and
  # including the first element for which the block returned true, and the
  # second being the rest of this array (or +nil+ if the block didn't
  # return true for any elements).
  def cut &block
    if (cut_at = index {|i| yield i }).nil?
      [self, nil]
    else
      [self[0...cut_at], self[cut_at..-1]]
    end
  end
  # Return two arrays in the same manner as +cut+, but check for element
  # equality against +value+ to find the point at which to cut the array.
  def cut_at value
    cut {|i| i == value }
  end
  # Return a new array containing every element from this array for which
  # the block returns true.
  def extract &block
    dup.extract! &block
  end
  # Like +extract+, but remove the extracted values in-place before
  # returning them.
  def extract! &block
    dup.inject [] do |extracted,i|
      extracted << delete(i) if yield i
      extracted
    end
  end
  # Return a new array containing all the elements from this array that
  # are neither +#nil?+ nor +#blank?+.
  def squash
    dup.squash!
  end
  # Like +squash+, but remove the +#nil?+ and +#blank?+ entries in-place.
  def squash!
    delete_if &:blank?
  end
  # First filter this array through through +#grep+ to contain only the
  # elements matching +by+, and then remove the search term from the
  # resulting elements.
  # This is useful for selecting items from a list based on some label,
  # and removing the label, in one step.
  # One good example is selecting the current branch from `git branch`
  # output. Given this repository:
  #   $ git branch
  #     master
  #   * next
  #     topic
  # You can use +#collapse+ to retrieve the current branch like this:
  #   shell('git branch').split("\n").collapse(/\* /) #=> ["docs"]
  def collapse by
    grep(by).map {|i| i.sub by, '' }
  end

  # Map this array to a new one by creating a VersionOf for each element in
  # turn.
  # If the element is a string, it's split at its first space to extract a
  # version. If the element is any other type, it's passed verbatim to
  # VersionOf.new (which may well fail).
  def versions
    map {|i|
      if i.is_a?(String)
        VersionOf.new *i.split(' ', 2)
      else
        VersionOf.new i
      end
    }
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
  # If +:suffix+ is set, it will be appended along with the correct linking verb,
  # i.e. 'is' for single-item lists and 'are' otherwise.
  #
  #   %w[coffee].to_list(:suffix => 'great') => "coffee is great"
  #   %w[Cîroc Żubrówka].to_list(:suffix => 'vodkas') #=> "Cîroc and Żubrówka are vodkas"
  #
  # If +:limit+ is set, only the first +:limit+ items will be included in the
  # output. If any elements were ommitted as a result, the suffix 'et al' will
  # be appended to indicate there are missing elements.
  #
  #   %w[latte espresso ristretto].to_list(:suffix => 'coffees', :limit => 2) #=> "latte, espresso et al are coffees"
  #
  # If +:noun+ is set in addition to +:limit+, it will be used to describe the
  # length of the list after 'et al' if any items were ommitted as a result of
  # the +:limit+ setting.
  #
  #   %w[latte espresso ristretto].to_list(:limit => 2, :noun => 'coffees') #=> "latte, espresso et al - 3 coffees"
  def to_list(opts = {})
    if opts[:limit].nil? || (self.length <= opts[:limit])
      [
        self[0..-2].squash.join(', '),
        last
      ].squash.join("#{',' if opts[:oxford]} #{opts[:conj] || 'and'} ")
    else
      self[0..(opts[:limit] - 1)].squash.join(', ') + ' et al' + (opts[:noun].nil? ? '' : " - #{self.length} #{opts[:noun]}")
    end +
    (opts[:suffix] ? " #{self.length > 1 ? 'are' : 'is'} #{opts[:suffix].strip}" : '')
  end

  # If the final element of the array is a +Hash+, it's removed from this array
  # and returned. Otherwise, an empty hash is returned.
  def extract_options!
    last.is_a?(::Hash) ? pop : {}
  end

  # Return a new array containing the terms from this array that were
  # determined to be 'similar to' +string+. A string is considered to
  # be similar to another if its Levenshtein distance is less than
  # either the string's length minus one, or one fifth is length plus
  # two, whichever is less.
  #
  #     word length  1  2  3  4  5  6  7  8  9  10  11  12  13  14  15  …
  #   typos allowed  0  0  1  2  3  3  3  3  3   4   4   4   4   4   5  …
  #
  # This means that:
  #   - a little over one fifth of strings longer than 4 characters can be misspelt;
  #   - strings 3 or 4 characters long can have 1 or 2 misspelt characters respectively;
  #   - strings 1 or 2 characters long must be spelt correctly.
  def similar_to string
    map {|term|
      [term, term.similarity_to(string)]
    }.select {|(i, similarity)|
      similarity <= [i.length - 2, (i.length / 5) + 2].min
    }.sort_by {|(i, similarity)|
      similarity
    }.map {|(i, similarity)|
      i
    }
  end
end
