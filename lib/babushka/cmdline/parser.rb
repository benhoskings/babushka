require 'optparse'

module Babushka
  module Cmdline
    class Parser
      attr_reader :verb, :argv, :opts

      def self.for argv
        if argv.empty? || (%w[-h --help] & argv).any?
          new 'help', argv
        elsif !Handler.abbrev.has_key?(argv.first.sub(/^--/, ''))
          new 'meet', argv, :implicit_verb => true
        else
          new Handler.abbrev[argv.shift.sub(/^--/, '')], argv
        end
      end

      def initialize verb, argv, parse_opts = {}
        @verb, @argv, @opts, @implicit_verb = verb, argv, {}, parse_opts[:implicit_verb]
        parse &Handler.for('global').opt_definer
        parse &Handler.for(verb).opt_definer
      end

      def run
        parser.parse! argv
        Handler.for(verb).handler.call self
      end

      def print_usage
        log parser.to_s.sub(/^Usage:.*$/, '')
      end

      def parse &blk
        instance_eval &blk
      end

      private

      def opt *args, &block
        opt_name = args.collapse(/^--/).first.gsub(/\s.*$/, '').gsub('-', '_').to_sym
        parser.on(*args) {|arg| opts[opt_name] = arg }
      end

      def parser
        @parser ||= OptionParser.new
      end
    end
  end
end
