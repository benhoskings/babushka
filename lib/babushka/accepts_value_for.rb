module Babushka
  module AcceptsValueFor
    def self.included base
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def accepts_value_for method_name, *args
        opts = args.extract_options!
        accepts_list_for method_name, *args.push(opts.merge(:type => 'value'))
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
