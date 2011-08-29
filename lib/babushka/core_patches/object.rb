alias :L :proc

class Object
  # Return this object's metaclass; i.e. the value of self within a
  # 'class << self' block.
  def metaclass
    class << self; self end
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
  class Object
    # Based on http://eigenclass.org/hiki/bounded+space+instance_exec
    #
    # But, this version runs against the object's metaclass, instead of
    # against a shared module on Object, so that methods defined within
    # the #instance_exec block aren't mistakenly defined on all instances
    # of the class.
    #
    # This is a fallback implementation for older rubies that don't have
    # a built-in #instance_exec.
    def instance_exec(*args, &block)
      n = 0
      n += 1 while respond_to?(method_name = "__instance_exec_#{n}")
      metaclass.send :define_method, method_name, &block
      send method_name, *args
    ensure
      metaclass.send :remove_method, method_name
    end
  end
end
