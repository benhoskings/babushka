require 'abbrev'

module Babushka
  module Cmdline

    def handle name, description, &blk
      Handler.add name, description, blk
    end
    module_function :handle

    class Handler
      def self.add name, description, opt_definer
        Handler.new(name, description, opt_definer).tap {|handler|
          (@handlers ||= []).push handler
        }
      end

      def self.all
        @handlers.reject {|h| h.name == 'global' }
      end

      def self.abbrev
        all.map(&:name).abbrev
      end

      def self.for name
        @handlers.detect {|h| h.name == name }
      end

      attr_reader :name, :description, :opt_definer, :handler

      def initialize name, description, opt_definer
        @name, @description, @opt_definer = name, description, (opt_definer || L{})
      end

      def run &handler
        @handler = handler
      end
    end
  end
end
