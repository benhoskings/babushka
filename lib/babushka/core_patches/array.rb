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

  def cut &block
    if (cut_at = index {|i| yield i }).nil?
      [self, nil]
    else
      [self[0...cut_at], self[cut_at..-1]]
    end
  end
  def cut_at value
    cut {|i| i == value }
  end
  def extract &block
    dup.extract! &block
  end
  def extract! &block
    dup.inject [] do |extracted,i|
      extracted << delete(i) if yield i
      extracted
    end
  end
  def squash
    dup.squash!
  end
  def squash!
    delete_if &:blank?
  end
  def collapse by
    grep(by).map {|i| i.sub by, '' }
  end
  def to_list(opts = {})
    if opts[:limit].nil? || (self.length <= opts[:limit])
      [
        self[0..-2].squash.join(', '),
        last
      ].squash.join("#{',' if opts[:oxford]} #{opts[:conj] || 'and'} ") +
      (opts[:suffix] ? " #{self.length > 1 ? 'are' : 'is'} #{opts[:suffix].strip}" : '')
    else
      self[0..(opts[:limit] - 1)].squash.join(', ') + ' et al' + (opts[:noun].nil? ? '' : " &mdash; #{self.length} #{opts[:noun]}")
    end
  end
  def extract_options!
    last.is_a?(::Hash) ? pop : {}
  end

  def similar_to string
    map {|term|
      [term, term.similarity_to(string)]
    }.select {|(i, similarity)|
      similarity <= [i.length - 1, (i.length / 5) + 2].min
    }.sort_by {|(i, similarity)|
      similarity
    }.map {|(i, similarity)|
      i
    }
  end
end
