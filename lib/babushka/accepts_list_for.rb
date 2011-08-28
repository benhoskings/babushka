module Babushka
  module AcceptsListFor
    def self.included base
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def accepts_list_for method_name, *args
        opts = {:type => 'list'}.merge args.extract_options!
        default = args.shift

        file, line = caller.first.split(':', 2)
        line = line.to_i

        module_eval <<-LOL, file, line
          def #{method_name} *args, &block
            if !args.empty? && !block.nil?
              raise ArgumentError, "You can supply arguments or a block, but not both."
            elsif args.empty? && block.nil?
              #{opts[:type]}_for #{method_name.inspect}, #{default.inspect}
            else
              store_#{opts[:type]}_for #{method_name.inspect}, block || [*args].flatten, #{opts[:choose_with].inspect}
              self
            end
          end
        LOL
      end
    end

    def store_list_for method_name, data, choose_with
      if data.respond_to? :call
        store_list_for method_name, LambdaChooser.new(self, *chooser_choices, &data).choose(chooser, choose_with), choose_with
      else
        (payload[method_name] ||= []).concat(data || [])
      end
    end

    def list_for method_name, default
      if payload.has_key? method_name
        payload[method_name].map {|i| i.respond_to?(:call) ? i.call : i }.compact
      else
        # Splatting on expressions instead of just a single token seems
        # to break the result in rubinius. https://gist.github.com/1173301
        values = default.is_a?(Symbol) ? send(default) : (default || [])
        [*values]
      end
    end
  end
end
