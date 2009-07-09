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
        @result = if block_given?
          block
        elsif first.is_a? Hash
          first
        else
          [*first].concat(rest)
        end
      end
    end

  end
end
