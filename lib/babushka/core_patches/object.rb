alias :L :proc

class Object
  # Return this object's metaclass; i.e. the value of self within a
  # 'class << self' block.
  def metaclass
    class << self; self end
  end

  # Return true if this object is +nil?+, or +empty?+ if it accepts that method.
  def blank?
    nil? || (respond_to?(:empty?) && empty?)
  end

  # Return this object after yielding it to the block. This is useful for
  # neatly working with an object in some way before returning it:
  #   def valmorphanize
  #     process.tap {|result|
  #       log "Oops!" unless result
  #     }
  #   end
  def tap &block
    yield self
    self
  end unless Object.respond_to?(:tap)

  # Return self unmodified after logging the output of #inspect, along with
  # the point at which +tapp+ was called.
  def tapp
    tap { puts "#{File.basename caller[2]}: #{self.inspect}" }
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
