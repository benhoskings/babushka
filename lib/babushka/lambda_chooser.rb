module Babushka
  class LambdaChooser

    attr_reader :owner

    def var(name, opts = {}) owner.var(name, opts) end

    def initialize owner, *possible_choices, &block
      raise ArgumentError, "You can't use :otherwise as a choice name, because it's reserved." if possible_choices.include?(:otherwise)
      @owner = owner
      @possible_choices = possible_choices.push(:otherwise)
      @block = block
      @results = {}
    end

    def choose choices, method_name = nil
      self.metaclass.send :alias_method, method_name, :on unless method_name.nil?
      block_result = instance_eval(&@block)
      @results.empty? ? block_result : [*choices].push(:otherwise).pick {|c| @results[c] }
    end

    def otherwise first = nil, *rest, &block
      on :otherwise, first, *rest, &block
    end

    def on choice, first = nil, *rest, &block
      raise "You can supply values or a block, but not both." if first && block
      raise "The choice '#{choice}' isn't valid." unless @possible_choices.include?(choice)

      @results[choice] = if block
        block
      elsif first.is_a? Hash
        first
      else
        [first].flatten(1).concat(rest)
      end
    end

  end
end
