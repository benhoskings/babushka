module Babushka
  module VersionList
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
        set_up_delegating_for method_name
      end

    end


    module InstanceMethods

      def store_list_for method_name, data
        if data.respond_to? :call
          store_list_for method_name, LambdaChooser.new(&data).choose(chooser)
        else
          (payload[method_name] ||= []).concat versions_for data
        end
      end

      def versions_for data
        if data.nil?
          []
        elsif data.is_a? Hash
          data.map {|name,version| ver name, version }
        elsif data.first.is_a? Hash
          data.first.map {|name,version| ver name, version }
        else
          data.map {|name| ver name }
        end
      end

      def list_for method_name, default
        if payload.has_key? method_name
          payload[method_name]
        else
          [*(default.is_a?(Symbol) ? send(default) : (default || []))]
        end
      end

    end
  end
end
