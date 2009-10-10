module Babushka
  class LambdaChooser

    def initialize *possible_choices, &block
      @possible_choices = possible_choices
      @block = block
      @results = {}
    end

    def choose choices, method_name = nil
      self.class.send :alias_method, (method_name || :on), :process_choice
      instance_eval &@block
      # @results[choices]
      [*choices].pick {|c| @results[c] }
    end

    def process_choice choice, first = nil, *rest, &block
      raise "You can supply values or a block, but not both." if first && block
      raise "The choice '#{choice}' isn't valid." unless choice.in? @possible_choices

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
