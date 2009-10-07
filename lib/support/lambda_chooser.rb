module Babushka
  class LambdaChooser

    def initialize &block
      @block = block
      @results = {}
    end

    def choose choice, choices
      setup choices
      instance_eval &@block
      @results[choice]
    end

    def setup choices
      choices.map {|choice|
        instance_eval <<-LOL
          def #{choice} first = nil, *rest, &block
            @results[#{choice.inspect}] = if block_given?
              block
            elsif first.is_a? Hash
              first
            else
              [*first].concat(rest)
            end
          end
        LOL
      }
    end

  end
end
