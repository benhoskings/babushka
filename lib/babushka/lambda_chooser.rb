module Babushka
  class LambdaChooser
    DEPRECATED_CHOICES = {
      :macports => ['2012-12-13', :brew]
    }

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
      @results.empty? ? block_result : [choices].flatten(1).push(:otherwise).pick {|c| @results[c] }
    end

    def otherwise first = nil, *rest, &block
      on :otherwise, first, *rest, &block
    end

    def on choices, first = nil, *rest, &block
      raise "You can supply values or a block, but not both." if first && block

      [choices].flatten(1).each {|choice|
        raise "The choice '#{choice}' isn't valid." unless @possible_choices.include?(choice)
        LogHelpers.log_warn "The #{choice.inspect} choice has been deprecated and will be removed on #{DEPRECATED_CHOICES[choice].first}. Use #{DEPRECATED_CHOICES[choice].last.inspect} instead." if DEPRECATED_CHOICES.keys.include?(choice)

        @results[choice] = if block
          block
        elsif first.is_a? Hash
          first
        else
          [first].flatten(1).concat(rest)
        end
      }
    end

  end
end
