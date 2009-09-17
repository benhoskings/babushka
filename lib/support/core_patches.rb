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
  include StartsAndEndsChecks

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

  def reject_r &block
    dup.each_pair {|k,v|
      if v.is_a? Hash
        self[k] = v.reject_r
      else
        self.delete k unless [String, Symbol].include?(v.class)
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

  def in? list
    list.include? self
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

end

unless :to_proc.respond_to? :to_proc
  class Symbol
    def to_proc
      L{|*args| args.shift.__send__ self, *args }
    end
  end
end

class Class # :nodoc:
  def class_inheritable_reader(*syms)
    syms.each do |sym|
      next if sym.is_a?(Hash)
      class_eval <<-EOS
        def self.#{sym}                        # def self.before_add_for_comments
          read_inheritable_attribute(:#{sym})  #   read_inheritable_attribute(:before_add_for_comments)
        end                                    # end
                                               #
        def #{sym}                             # def before_add_for_comments
          self.class.#{sym}                    #   self.class.before_add_for_comments
        end                                    # end
      EOS
    end
  end

  def class_inheritable_writer(*syms)
    options = syms.extract_options!
    syms.each do |sym|
      class_eval <<-EOS
        def self.#{sym}=(obj)                          # def self.color=(obj)
          write_inheritable_attribute(:#{sym}, obj)    #   write_inheritable_attribute(:color, obj)
        end                                            # end
                                                       #
        #{"                                            #
        def #{sym}=(obj)                               # def color=(obj)
          self.class.#{sym} = obj                      #   self.class.color = obj
        end                                            # end
        " unless options[:instance_writer] == false }  # # the writer above is generated unless options[:instance_writer] == false
      EOS
    end
  end

  def class_inheritable_accessor(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_writer(*syms)
  end

  def inheritable_attributes
    @inheritable_attributes ||= EMPTY_INHERITABLE_ATTRIBUTES
  end

  def write_inheritable_attribute(key, value)
    if inheritable_attributes.equal?(EMPTY_INHERITABLE_ATTRIBUTES)
      @inheritable_attributes = {}
    end
    inheritable_attributes[key] = value
  end

  def read_inheritable_attribute(key)
    inheritable_attributes[key]
  end

  private

  # Prevent this constant from being created multiple times
  EMPTY_INHERITABLE_ATTRIBUTES = {}.freeze unless const_defined?(:EMPTY_INHERITABLE_ATTRIBUTES)

end
