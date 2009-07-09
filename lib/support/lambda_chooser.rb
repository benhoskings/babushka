module Babushka
  class LambdaChooser

    def initialize &block
      @block = block
    end

    def choose name = nil
      if (@name = name).nil?
        @block.call
      else
        instance_eval &@block
        @result
      end
    end

    def method_missing method_name, *args, &block
      if @name == method_name
        @result = block_given? ? block : [*args]
      end
    end

  end
end
