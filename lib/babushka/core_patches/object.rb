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
  #       log_error "Oops!" unless result
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
