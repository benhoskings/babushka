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
      @value.to_s
    end

    def to_str
      @value.to_str
    end
  end
end
