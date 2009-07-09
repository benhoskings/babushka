module Babushka
  module LambdaList
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def accepts_list_for method_name, default = nil
        define_method method_name do |*args, &block|
          if !args.blank? && !block.nil?
            raise ArgumentError, "You can supply arguments or a block, but not both."
          elsif args.blank? && block.nil?
            list_for method_name, default
          else
            store_list_for method_name, block || [*args].flatten
            self
          end
        end
      end

    end


    module InstanceMethods

      def store_list_for method_name, data
        if data.respond_to? :call
          store_list_for method_name, LambdaChooser.new(&data).choose(chooser)
        elsif !data.nil?
          payload[method_name] = data.first.is_a?(Hash) ? data.first : data
        end
      end

      def list_for method_name, default
        payload[method_name] || [*(default.is_a?(Symbol) ? send(default) : (default || []))]
      end

    end
  end
end
