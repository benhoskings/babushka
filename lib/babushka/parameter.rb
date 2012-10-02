module Babushka
  class Parameter
    attr_reader :name

    def self.for name, value = nil
      value.is_a?(Parameter) ? value : Parameter.new(name, value)
    end

    def initialize(name, value = nil)
      @name = name
      @value = value
    end

    # If #default! is set, the parameter's value will default to it lazily when
    # it's requested, without prompting. If the parameter is set, though (i.e.
    # if an explicit value was supplied, say on the command line), it will
    # override the #default! value.
    #
    # This is useful for setting parameters that have a "standard" value of some
    # kind that won't usually need to be customised.
    #
    # For example, the deps that install babushka itself use a :branch parameter
    # that has #default! set to 'master'. This means that the installation
    # process will install the 'master' branch without asking the user to choose
    # a branch, but a custom branch can still be specified by passing an
    # explicit value, for example by passing 'branch=next' on the command line.
    def default! value
      tap { @default_bang = value }
    end

    # If #default is set, then when this parameter lazily prompts for a value,
    # it will pass #default to Prompt as the default. That is, Prompt will
    # return #default's value if the user just hits 'enter', if '--defaults' was
    # passed on the commandline, or if babushka is running on a non-terminal
    # STDIN.
    #
    # This is useful for setting parameters that should be customised, or maybe
    # just confirmed by the user, each time the dep is run.
    #
    # For example, the deps that install babushka itself use a :path parameter
    # that has #default set to '/usr/local/babushka' (unless babushka is already
    # in the path, in which case it's a non-prompting default). This means that
    # babushka will ask for a path when it's installed, providing
    # '/usr/local/babushka' as the "just-hit-enter" default.
    def default value
      tap { @default = value }
    end

    # If #ask is set, then when this parameter lazily prompts for a value, it
    # will pass #ask to Prompt as the message. That is, Prompt will use this
    # string, ending it with a question mark, as the question it shows to the
    # user to give them information about the value it's requesting.
    #
    # For example, the deps that install babushka itself use a :path parameter.
    # if #ask wasn't specified, it would prompt the user with just 'path?',
    # which isn't very clear. Instead, #ask is set to 'Where would you like
    # babushka installed', which, along with the default value, makes it clear
    # to the user what they're being asked for.
    def ask value
      tap { @ask = value }
    end

    # If #choose is set, then when this parameter lazily prompts for a value, it
    # will only accept a value that is in #choose's list.
    #
    # You can pass either an array or a hash to #choose. If you pass an array of
    # values, Prompt will only accept a value that's included in the array. If
    # you pass a hash of {value => description}, Prompt will only accept a value
    # that's included in the hash's keys, printing a list of the corresponding
    # descriptions before asking for the value.
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

    def to_a
      value.to_a
    end

    def each
      value.each { |i| yield i }
    end

    def to_str
      if !value.respond_to?(:to_str)
        raise TypeError, "Can't coerce #{value}:#{value.class.name} into a String"
      else
        value.to_str
      end
    end

    def current_value
      @value
    end

    def inspect
      "#<Babushka::Parameter:#{object_id} #{description}>"
    end

    def description
      if @value
        "#{name}: #{inspect_truncated(@value)}"
      elsif @default_bang
        "#{name}: [default!: #{inspect_truncated(@default_bang)}]"
      elsif @default
        "#{name}: [default: #{inspect_truncated(@default)}]"
      else
        "#{name}: [unset]"
      end
    end

  private

    def value
      @value ||= @default_bang || Prompt.get_value((@ask || name).to_s, prompt_opts)
    end

    def inspect_truncated value
      value.inspect.sub(/^(.{50})(.{3}).*/m, '\1...')
    end

    def prompt_opts
      {}.tap {|hsh|
        hsh[:default] = @default unless @default.nil?
        hsh[:choices] = @choose if @choose.is_a?(Array)
        hsh[:choice_descriptions] = @choose if @choose.is_a?(Hash)
      }
    end
  end
end
