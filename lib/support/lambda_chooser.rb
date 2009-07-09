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

    def method_missing method_name, first = nil, *rest, &block
      if @name == method_name
        @result = block_given? ? block : [*first].concat(rest)
      end
    end

  end
end
