module Babushka
  class Vars
    include LogHelpers

    attr_reader :vars, :saved_vars

    module Helpers
      def set(key, value) Base.task.vars.set(key, value) end
      def merge(key, value) Base.task.vars.merge(key, value) end
      def var(name, opts = {}) Base.task.vars.var(name, opts) end
      def define_var(name, opts = {}) Base.task.vars.define_var(name, opts) end
      def default_for_ask(bool) Base.task.vars.default_for_ask(bool) end
    end

    def initialize
      @vars = Hashish.hash
      @saved_vars = Hashish.hash
      @default_for_ask = true
    end

    def set key, value
      vars[key.to_s][:value] = value
    end
    def merge key, value
      set key, ((vars[key.to_s] || {})[:value] || {}).merge(value)
    end

    def var name, opts = {}
      define_var name, opts
      opts[:ask] = @default_for_ask unless opts.has_key? :ask
      if vars[name.to_s].has_key? :value
        if vars[name.to_s][:value].respond_to? :call
          vars[name.to_s][:value].call
        else
          vars[name.to_s][:value]
        end
      elsif opts[:ask] != false
        ask_for_var name.to_s, opts
      else
        default_for name
      end
    end

    def default_for_ask(bool)
      @default_for_ask = bool
    end

    def define_var name, opts = {}
      vars[name.to_s].update opts.slice(:default, :type, :message, :choices, :choice_descriptions)
      vars[name.to_s][:choices] ||= vars[name.to_s][:choice_descriptions].keys unless vars[name.to_s][:choice_descriptions].nil?
      vars[name.to_s]
    end

    def for_save
      vars.dup.inject(saved_vars.dup) {|vars_to_save,(var,_)|
        vars_to_save[var].update vars[var]
        save_referenced_default_for(var, vars_to_save) if vars[var][:default].is_a?(Symbol)
        vars_to_save
      }.reject_r {|var,data|
        ![String, Symbol, Hash, Numeric, TrueClass, FalseClass].include?(data.class) ||
        var.to_s['password']
      }
    end

    def default_for key
      if vars[key.to_s][:default].respond_to? :call
        # If the default is a proc, re-evaluate it every time.
        instance_eval { vars[key.to_s][:default].call }

      elsif saved_vars[key.to_s].has_key? :value
        # Otherwise, if there's a saved value, use that.
        saved_vars[key.to_s][:value]

      # Symbol defaults are references to other vars.
      elsif vars[key.to_s][:default].is_a? Symbol
        # Look up the current value of the referenced var.
        referenced_val = var vars[key.to_s][:default], :ask => false
        # Use the corresponding saved value if there is one, otherwise use the reference.
        (saved_vars[key.to_s][:values] ||= {})[referenced_val] || referenced_val

      else
        # Otherwise, use the default.
        vars[key.to_s][:default]
      end
    end


    private

    def ask_for_var key, opts
      set key, Prompt.send("get_#{vars[key][:type] || 'value'}",
        message_for(key),
        vars[key].slice(:choices, :choice_descriptions).merge(
          opts
        ).merge(
          :default => default_for(key),
          :dynamic => vars[key][:default].respond_to?(:call)
        )
      )
    end

    def message_for key
      printable_key = key.to_s.gsub '_', ' '
      vars[key][:message] || printable_key
    end

    def save_referenced_default_for var, vars_to_save
      vars_to_save[var][:values] ||= {}
      vars_to_save[var][:values][ # set the saved value of this var
        vars[vars[var][:default].to_s][:value] # for this var's current default reference
      ] = vars_to_save[var].delete(:value) # to the referenced var's value
    end

  end
end
