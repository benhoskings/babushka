module Babushka
  module AcceptsFor
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def accepts_value_for method_name, *args
        opts = args.extract_options!
        accepts_list_for method_name, *args.push(opts.merge(:type => 'value'))
      end

      def accepts_list_for method_name, *args
        opts = {:type => 'list'}.merge args.extract_options!
        default = args.shift

        file, line = caller.first.split(':', 2)
        line = line.to_i

        module_eval <<-LOL, file, line
          def #{method_name} *args, &block
            if !args.blank? && !block.nil?
              raise ArgumentError, "You can supply arguments or a block, but not both."
            elsif args.blank? && block.nil?
              #{opts[:type]}_for #{method_name.inspect}, #{default.inspect}
            else
              store_#{opts[:type]}_for #{method_name.inspect}, block || [*args].flatten, #{opts[:choose_with].inspect}
              self
            end
          end
        LOL
        set_up_delegating_for method_name
      end

    end


    module InstanceMethods

      def store_list_for method_name, data, choose_with
        if data.respond_to? :call
          store_list_for method_name, LambdaChooser.new(self, *chooser_choices, &data).choose(chooser, choose_with), choose_with
        else
          (payload[method_name] ||= []).concat(data || [])
        end
      end

      def versions_for data
        if data.nil?
          []
        else
          data.map {|name| name.is_a?(String) ? ver(name) : name }
        end
      end

      def list_for method_name, default
        if payload.has_key? method_name
          payload[method_name].map {|i| i.respond_to?(:call) ? i.call : i }
        else
          [*(default.is_a?(Symbol) ? send(default) : (default || []))]
        end
      end

      def store_value_for method_name, data, choose_with
        raise "Multiple values for #{method_name}" if data.respond_to?(:length) && data.length > 1
        payload.delete(method_name) # otherwise new values would be #concat'ed and ignored.
        store_list_for method_name, data, choose_with
      end

      def value_for method_name, default
        list_for(method_name, default).first
      end

    end
  end
end
