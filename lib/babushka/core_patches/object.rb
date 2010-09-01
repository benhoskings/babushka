alias :L :proc

class Object
  # Yield the supplied object to the block before returning it. This is useful
  # for writing cleaner object creations and related things. For example:
  #   returning [] do |list|
  #     list << 'value' if condition
  #   end
  def returning obj, &block
    yield obj
    obj
  end

  # The opposite of Array#include - i.e. return true if self appears in the
  # array splatted into +first+ and +rest+.
  def in? first, *rest
    (first.is_a?(Array) ? first : [first].concat(rest)).include? self
  end

  # Return this object's metaclass; i.e. the value of self within a
  # 'class << self' block.
  def metaclass
    class << self; self end
  end

  def singleton
    Class.new self
  end

  def recursive_const_get name
    name.split('::').inject(Object) {|klass,name| klass.const_get name }
  end

  # Return true if this object is +nil?+, or +empty?+ if it accepts that method.
  def blank?
    nil? || (respond_to?(:empty?) && empty?)
  end

  # Return this object after yielding it to the block. This is useful for
  # easily inserting logging, among other things. Given this code:
  #   values.map(&:name).join(', ')
  # You can easily insert logging like so:
  #   values.map(&:name).tap {|i| log i }.join(', ')
  def tap &block
    returning(self) { yield self }
  end

  # Return self unmodified after logging the output of #inspect, along with
  # the point at which +tapp+ was called.
  def tapp
    tap { puts "#{File.basename caller[4]}: #{self.inspect}" }
  end
  # Log and return unmodified in the same manner as #tapp, but escape the
  # output to be HTML safe and easily readable. For example,
  #   #<Object:0x00000100bda208>
  # becomes
  #   #&lt;Object:0x00000100bda208><br />
  def taph
    tap { puts("#{File.basename caller[4]}: #{self.inspect}".gsub('&', '&amp;').gsub('<', '&lt;') + "<br />") }
  end
  require 'pp'
  def tappp
    tap { pp self }
  end
  def tap_log
    returning(self) { log_verbose self }
  end
end

unless Object.new.respond_to? :instance_exec
  # http://eigenclass.org/hiki/bounded+space+instance_exec
  class Object
    module InstanceExecHelper; end
    include InstanceExecHelper

    # Executes the given block within the context of the receiver. In
    # order to set the context, the variable self is set to this object
    # while the block is executing, giving the code access to this object's
    # instance variables. Arguments are passed as block parameters.
    #
    # This is a fallback implementation for older rubies that don't have
    # a built-in #instance_exec.
    def instance_exec(*args, &block)
      begin
        old_critical, Thread.critical = Thread.critical, true
        n = 0
        n += 1 while respond_to?(mname="__instance_exec#{n}")
        InstanceExecHelper.module_eval{ define_method(mname, &block) }
      ensure
        Thread.critical = old_critical
      end
      begin
        ret = send(mname, *args)
      ensure
        InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
      end
      ret
    end
  end
end
