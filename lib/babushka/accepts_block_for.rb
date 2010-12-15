module Babushka
  module AcceptsBlockFor
    def self.included base
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def default_blocks
        merged_default_blocks_for self
      end
      def merged_default_blocks_for klass
        parent_values = klass == DepDefiner ? {} : merged_default_blocks_for(klass.superclass)
        parent_values.merge(default_blocks_for(klass))
      end
      def default_blocks_for klass
        (@@default_blocks ||= Hashish.hash)[klass]
      end

      def accepted_blocks
        default_blocks.keys
      end

      def accepts_block_for method_name, &default_block
        default_blocks_for(self)[method_name] = default_block
        class_eval %Q{
          def #{method_name} *args, &block
            payload[#{method_name.inspect}] ||= {}
            if block.nil?
              block_for #{method_name.inspect}
            else
              store_block_for #{method_name.inspect}, args, block
            end
          end
        }
      end
    end

    def default_blocks
      self.class.default_blocks
    end

    def store_block_for method_name, args, block
      raise "#{method_name} only accepts args like :on => :linux (as well as a block arg)." unless args.empty? || args.first.is_a?(Hash)

      payload[method_name] ||= {}
      chosen_on = (args.first || {})[:on] || @current_platform || :all
      payload[method_name][chosen_on] = block
    end

    def block_for method_name
      specific_block_for(method_name) or default_task(method_name)
    end

    def specific_block_for method_name
      payload[method_name][(Base.host.match_list & payload[method_name].keys).first] ||
      default_blocks[method_name]
    end
  end
end
