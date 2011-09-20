module Babushka
  class Parameter
    attr_reader :name

    def initialize(name, value = nil)
      @name = name
      @value = value
    end

    def suggest value
      tap { @suggest = value }
    end
    def ask value
      tap { @ask = value }
    end
    def choose *value
      tap {
        @choose = if [[Hash], [Array]].include?(value.map(&:class))
          value.first
        else
          value
        end
      }
    end

    def set?
      !!@value
    end

    def == other
      value == other
    end

    def / other
      value / other
    end

    def [] other
      value[other]
    end

    def p
      value.p
    end

    def to_s
      value.to_s
    end

    def to_str
      if !value.respond_to?(:to_str)
        raise TypeError, "Can't coerce #{value}:#{value.class.name} into a String"
      else
        value.to_str
      end
    end

    def inspect
      "#<Babushka::Parameter:#{object_id} #{name}: #{@value || '[unset]'}>"
    end

  private

    def value
      @value ||= Prompt.get_value((@ask || name).to_s, prompt_opts)
    end

    def prompt_opts
      {}.tap {|hsh|
        hsh[:default] = @suggest unless @suggest.nil?
        hsh[:choices] = @choose if @choose.is_a?(Array)
        hsh[:choice_descriptions] = @choose if @choose.is_a?(Hash)
      }
    end
  end
end
