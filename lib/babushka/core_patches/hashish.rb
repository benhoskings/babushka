class Hashish
  # Return a new hash whose default value is an empty array; i.e. querying any
  # un-assigned key will assign and return an empty array to that key.
  def self.array
    Babushka::LogHelpers.deprecated! '2017-09-01', instead: "`Hash.new {|hsh,k| hsh[k] = [] }`"
    Hash.new {|hsh,k| hsh[k] = [] }
  end

  # Return a new hash whose default value is an empty hash; i.e. querying any
  # un-assigned key will assign and return an empty hash to that key. Note that
  # the empty hash is a regular hash and doesn't have any default keys of its own.
  def self.hash
    Babushka::LogHelpers.deprecated! '2017-09-01', instead: "`Hash.new {|hsh,k| hsh[k] = {} }`"
    Hash.new {|hsh,k| hsh[k] = {} }
  end
end
