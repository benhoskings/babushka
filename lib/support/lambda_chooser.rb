module Babushka
  class LambdaChooser

    def initialize *choices, &block
      @choices = choices
      @block = block
      @results = {}
    end

    def choose choice, method_name = nil
      self.class.send :alias_method, (method_name || :on), :process_choice
      instance_eval &@block
      @results[choice]
    end

    def process_choice choice, first = nil, *rest, &block
      raise "You can supply values or a block, but not both." if first && block
      raise "The choice '#{choice}' isn't valid." unless choice.in? @choices

      @results[choice] = if block
        block
      elsif first.is_a? Hash
        first
      else
        [*first].concat(rest)
      end
    end

  end
end
