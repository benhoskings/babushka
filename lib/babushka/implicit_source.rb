module Babushka
  class ImplicitSource < Source

    def initialize name
      raise ArgumentError, "Implicit sources require a name." if name.nil?
      init
      @name = name
    end

    def type
      :implicit
    end

    def path
      nil
    end

  end
end
