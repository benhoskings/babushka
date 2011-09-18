module Babushka
  class Arg
    attr_reader :name

    def initialize(name, value = nil)
      @name = name
      @value = value
    end

    def set?
      !!@value
    end

    def to_s
      value.to_s
    end

    def to_str
      value.to_str
    end

  private

    def value
      @value ||= Prompt.get_value(name.to_s)
    end
  end
end
