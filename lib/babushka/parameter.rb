module Babushka
  class Parameter
    attr_reader :name

    def initialize(name, value = nil)
      @name = name
      @value = value
    end

    def default value
      tap { @default = value }
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

    def inspect
      "#<Babushka::Parameter:#{object_id} #{name}: #{@value || '[unset]'}>"
    end

  private

    def value
      @value ||= Prompt.get_value(name.to_s, :default => @default)
    end
  end
end
