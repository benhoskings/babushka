module StartsAndEndsChecks
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
end

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
  def to_list(opts = {})
    if opts[:limit].nil? || (self.length <= opts[:limit])
      [
        self[0..-2].squash.join(', '),
        last
      ].squash.join(" #{opts[:conj] || 'and'} ") +
      (opts[:suffix] ? " #{self.length > 1 ? 'are' : 'is'} #{opts[:suffix].strip}" : '')
    else
      self[0..(opts[:limit] - 1)].squash.join(', ') + ' et al' + (opts[:noun].nil? ? '' : " &mdash; #{self.length} #{opts[:noun]}")
    end
  end
  def extract_options!
    last.is_a?(::Hash) ? pop : {}
  end

  def similar_to string, threshold = 3
    select {|i| i.similarity_to(string) < threshold }
  end

  def describe_as_ip
    if length != 4
      false
    elsif starts_with? 0 # Source hosts on "this" network
      :reserved
    elsif starts_with? 127 # Loopback network; RFC1700
      :loopback
    elsif starts_with? 10 # Class-A private; RFC1918
      :private
    elsif starts_with?(172) && ((16..31) === self[1]) # Class-B private; RFC1918
      :private
    elsif starts_with? 169, 254 # Link-local range; RFC3330/3927
      self[2].in?(0, 255) ? :reserved : :self_assigned
    elsif starts_with? 192, 0, 2 # TEST-NET - used as example.com IP
      :reserved
    elsif starts_with? 192, 88, 99 # 6-to-4 relay anycast; RFC3068
      :reserved
    elsif starts_with? 192, 168 # Class-C private; RFC1918
      :private
    elsif starts_with? 198, 18 # Benchmarking; RFC2544
      :reserved
    else
      :public
    end
  end
end

class Module
  def delegate *args
    opts = args.last.is_a?(Hash) ? args.pop : {}
    raise ArgumentError, "You need to supply :to => target as the final argument." if opts[:to].nil?

    file, line = caller.first.split(':', 2)
    line = line.to_i

    args.each {|method_name|
      module_eval <<-EOS, file, line
        def #{method_name} *args, &block
          #{opts[:to]}.__send__ #{method_name.inspect}, *args, &block
        end
      EOS
    }
  end
end

require 'etc'

class File
  def self.owner filename
    Etc.getpwuid(File.stat(filename).uid).name
  end
end

class Hash
  def dragnet *keys
    dup.dragnet! *keys
  end

  def dragnet! *keys
    keys.inject({}) {|acc,key|
      acc[key] = self.delete(key) if self.has_key?(key)
      acc
    }
  end

  def map_values &block
    dup.map_values! &block
  end

  def map_values! &block
    keys.each {|k|
      self[k] = yield k, self[k]
    }
    self
  end

  def selekt &block
    hsh = {}
    each_pair {|k,v|
      hsh[k] = v if yield(k,v)
    }
    hsh
  end

  def reject_r &block
    dup.reject_r! &block
  end

  def reject_r! &block
    each_pair {|k,v|
      if yield k, v
        self.delete k
      elsif v.is_a? Hash
        self[k] = v.reject_r &block
      end
    }
  end
end

class Hashish
  def self.array
    Hash.new {|hsh,k| hsh[k] = [] }
  end
  def self.hash
    Hash.new {|hsh,k| hsh[k] = {} }
  end
end

class IO
  def ready_for_read?
    result = IO.select([self], [], [], 0)
    result && (result.first.first == self)
  end
end

class Numeric
  def commas
    if self < 1000
      self
    else
      whole, fract = self.to_s.split('.')
      [ whole.reverse.scan(/\d{1,3}/).join(',').reverse, fract ].squash.join('.')
    end
  end
end

class Integer
  def xsecs
    value = self.abs
    past = (self < 0)

    case value
    when 0; return 'now'
    when 1...60; return "less than a minute#{' ago' if past}"
    when 61...3600;        value /= 60;        unit = 'minute'
    when 3600...(3600*24); value /= 3600;      unit = 'hour'
    else                   value /= (3600*24); unit = 'day'
    end

    value = 1 if value == 0
    "#{value.commas} #{unit}#{'s' unless value == 1}#{' ago' if past}"
  end
end

class Object
  def returning obj, &block
    yield obj
    obj
  end

  def in? first, *rest
    (first.is_a?(Array) ? first : [first].concat(rest)).include? self
  end

  def metaclass
    class << self; self end
  end

  def singleton
    Class.new self
  end

  def recursive_const_get name
    name.split('::').inject(Object) {|klass,name| klass.const_get name }
  end

  def blank?
    nil? || (respond_to?(:empty?) && empty?)
  end

  def tap &block
    returning(self) { yield self }
  end
  def tapp
    tap { puts "#{File.basename caller[4]}: #{self.inspect}" }
  end
  require 'pp'
  def tappp
    tap { pp self }
  end
  def tap_log
    returning(self) { log_verbose self }
  end
end

class String
  include StartsAndEndsChecks

  def val_for key
    split("\n").grep(
      key.is_a?(Regexp) ? key : /\b#{key}\b/
    ).map {|l|
      l.sub(key.is_a?(Regexp) ? key : /\b#{key}\b[:=]?/, '').sub(/;\s*$/, '').strip
    }.first || ''
  end
  def / other
    empty? ? other.to_s : File.join(self, other.to_s)
  end

  def words
    split(/[^a-z0-9_.-]+/i)
  end

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

  # Returns whether this IP should be considered a valid one for a client to be using.
  def valid_ip?
    describe_as_ip.in? :public, :private, :loopback
  end

  def valid_ip_range?
    describe_as_ip_range
  end

  # Returns a symbol describing the class of IP address +self+ represents, if any.
  #
  # Examples:
  #
  #     "Hello world!".valid_ip?   #=> false
  #     "192.168.".valid_ip?       #=> false
  #     "127.0.0.1".valid_ip?      #=> :loopback
  #     "172.24.137.6".valid_ip?   #=> :private
  #     "169.254.1.142".valid_ip?  #=> :self_assigned
  #     "72.9.108.122".valid_ip?   #=> :public
  def describe_as_ip
    sanitize_as_ip {|str,val|
      val if ((1..255) === val) || (val == 0 && str == '0')
    }.describe_as_ip
  end

  def describe_as_ip_range
    if /^\d+(\.\d+)*(\.x)+$/ =~ self
      sanitize_as_ip {|str,val|
        if ((1..255) === val) || (val == 0 && str == '0')
          val
        elsif str == 'x'
          str
        end
      }
    end
  end

  def sanitize_as_ip &block
    parts = strip.split('.')
    bytes = parts.zip(
      parts.map(&:to_i)
    ).map {|(str,val)|
      yield str, val
    }.squash
  end

end

unless :to_proc.respond_to? :to_proc
  class Symbol
    def to_proc
      L{|*args| args.shift.__send__ self, *args }
    end
  end
end
