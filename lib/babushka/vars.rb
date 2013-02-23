module Babushka
  module Vars
    module Helpers
      def set(key, value)
        removed! :instead => 'an argument for a dep parameter', :example => "requires 'some dep'.with(:#{key} => '#{value}')"
      end

      def merge(key, value)
        removed! :instead => 'an argument for a dep parameter', :example => "requires 'some dep'.with(:#{key} => '#{value}')"
      end

      def var(name, opts = {})
        print_var_removal_for('#var', name, opts)
      end

      def define_var(name, opts = {})
        print_var_removal_for('#define_var', name, opts)
      end

      def print_var_removal_for method_name, var_name, opts
        option_names_map = {
          :default => :default,
          :message => :ask,
          :choices => :choose,
          :choice_descriptions => :choose
        }
        param_opts = opts.slice(*option_names_map.keys).keys.map {|key|
          opt_value = opts[key].respond_to?(:call) ? '...' : opts[key].inspect
          "#{option_names_map[key]}(#{opt_value})"
        }
        example = if param_opts.empty?
          "dep 'blah', :#{name} do ... end"
        else
          "
dep 'blah', :#{var_name} do
  #{[var_name].concat(param_opts).join('.')}
end"
        end
        removed! \
          :skip => 2,
          :method_name => method_name,
          :instead => 'a dep parameter',
          :example => example
      end
    end

  end
end
