module Babushka
  module VersionList
    def self.included base
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def accepts_list_for method_name, *args
        opts = args.extract_options!
        default = args.shift

        file, line = caller.first.split(':', 2)
        line = line.to_i

        module_eval <<-LOL, file, line
          def #{method_name} *args, &block
            if !args.blank? && !block.nil?
              raise ArgumentError, "You can supply arguments or a block, but not both."
            elsif args.blank? && block.nil?
              list_for #{method_name.inspect}, #{default.inspect}
            else
              store_list_for #{method_name.inspect}, block || [*args].flatten, #{opts[:choose_with].inspect}
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
          (payload[method_name] ||= []).concat versions_for data
        end
      end

      def versions_for data
        if data.nil?
          []
        elsif data.is_a? Hash
          data.map {|name,version| ver name, version }
        elsif data.first.is_a? Hash
          versions_for data.first
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
