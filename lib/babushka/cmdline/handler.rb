require 'abbrev'

module Babushka
  class Cmdline

    def self.handle name, description, &blk
      Handler.add name, description, blk
    end

    def self.fail_with message
      log message if message.is_a? String
      exit 1
    end

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
