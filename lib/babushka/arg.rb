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
  end
end
