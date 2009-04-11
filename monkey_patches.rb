class Object
  def in? list
    list.include? self
  end
end

class String
  # Returns true iff +str+ appears exactly at the start of +self+.
  def starts_with? str
    self[0, str.length] == str
  end

  # Returns true iff +str+ appears exactly at the end of +self+.
  def ends_with? str
    self[-str.length, str.length] == str
  end

  # Return a duplicate of +self+, with +str+ prepended to it if it doesn't already start with +str+.
  def start_with str
    starts_with?(str) ? self : str + self
  end

  # Return a duplicate of +self+, with +str+ appended to it if it doesn't already end with +str+.
  def end_with str
    ends_with?(str) ? self : self + str
  end

  def val_for key
    split("\n").grep(key).first.sub(/^#{key}\:?/).strip
  end
  def / other
    File.join self, other
  end
end
