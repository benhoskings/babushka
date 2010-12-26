module Babushka
  class Vars
    include PromptHelpers

    attr_reader :vars, :saved_vars

    def initialize
      @vars = Hashish.hash
      @saved_vars = Hashish.hash
    end

    def set key, value
      vars[key.to_s][:value] = value
    end
    def set_if_unset key, value
      vars[key.to_s][:value] ||= value
    end
    def merge key, value
      set key, ((vars[key.to_s] || {})[:value] || {}).merge(value)
    end

    def var name, opts = {}
      define_var name, opts
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

    def sticky_var name, opts = {}
      var name, opts.merge(:sticky => true)
    end

    def define_var name, opts = {}
      vars[name.to_s].update opts.dragnet(:default, :type, :sticky, :message, :choices, :choice_descriptions)
      vars[name.to_s][:choices] ||= vars[name.to_s][:choice_descriptions].keys unless vars[name.to_s][:choice_descriptions].nil?
      vars[name.to_s]
    end

    def for_save
      vars.dup.inject(saved_vars.dup) {|vars_to_save,(var,data)|
        vars_to_save[var].update vars[var]
        save_referenced_default_for(var, vars_to_save) if vars[var][:default].is_a?(Symbol)
        vars_to_save
      }.reject_r {|var,data|
        !data.class.in?([String, Symbol, Hash, Numeric, TrueClass, FalseClass]) ||
        var.to_s['password']
      }
    end

    def sticky_for_save
      vars.reject {|var,data|
        !data[:sticky]
      }.map_values {|k,v|
        v.reject {|k,v| k != :value }
      }
    end

    def default_for key
      if vars[key.to_s][:default].respond_to? :call
        # If the default is a proc, re-evaluate it every time.
        instance_eval { vars[key.to_s][:default].call }
      # Symbol defaults are references to other vars.
      elsif vars[key.to_s][:default].is_a? Symbol
        # Look up the current value of the referenced var.
        referenced_val = var vars[key.to_s][:default], :ask => false
        # Use the corresponding saved value if there is one, otherwise use the reference.
        (saved_vars[key.to_s][:values] ||= {})[referenced_val] || referenced_val
      else
        # Otherwise, use a saved literal value, or the default.
        saved_vars[key.to_s][:value] || vars[key.to_s][:default]
      end
    end


    private

    def ask_for_var key, opts
      set key, send("prompt_for_#{vars[key][:type] || 'value'}",
        message_for(key),
        vars[key].dragnet(:choices, :choice_descriptions).merge(
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
