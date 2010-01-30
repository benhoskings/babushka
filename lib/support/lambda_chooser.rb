module Babushka
  class LambdaChooser

    attr_reader :owner
    delegate :var, :to => :owner

    def initialize owner, *possible_choices, &block
      @owner = owner
      @possible_choices = possible_choices
      @block = block
      @results = {}
    end

    def choose choices, method_name = nil
      self.class.send :alias_method, (method_name || :on), :process_choice
      block_result = instance_eval &@block
      @results.empty? ? block_result : [*choices].pick {|c| @results[c] }
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
