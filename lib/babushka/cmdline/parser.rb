require 'optparse'

module Babushka
  class Cmdline
    class Parser
      include LogHelpers

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
        @verb, @argv, @opts, @implicit_verb = verb, argv, default_opts, parse_opts[:implicit_verb]
        parse(&Handler.for('global').opt_definer)
        parse(&Handler.for(verb).opt_definer)
      end

      def run
        parser.parse! argv
        Handler.for(verb).handler.call self
      rescue OptionParser::ParseError => e
        log_error "The #{e.args.first} option #{error_reason(e)}. #{hint}"
      end

      def print_usage
        log parser.to_s.sub(/^Usage:.*$/, '')
      end

      def parse &blk
        instance_eval(&blk)
      end

      private

      def default_opts
        {
          :"[no_]color" => $stdout.tty?
        }
      end

      def hint
        "`babushka#{" #{verb}" unless @implicit_verb} --help` for more info."
      end

      def error_reason e
        {
          OptionParser::MissingArgument => "requires an argument"
        }[e.class] || "isn't valid"
      end

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
