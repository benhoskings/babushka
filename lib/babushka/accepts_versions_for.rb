module Babushka
  module AcceptsVersionsFor
    def self.included base
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def accepts_versions_for method_name, *args
        opts = args.extract_options!
        accepts_list_for method_name, *args.push(opts.merge(:type => 'versions'))
      end
    end

    def store_versions_for method_name, data, choose_with
      store_list_for method_name, data, choose_with
    end

    def versions_for method_name, default
      list_for method_name, default
    end
  end
end
