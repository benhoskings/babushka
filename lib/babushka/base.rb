module Babushka
  VERSION = '0.6.1'

  class Base
  class << self

    def task
      @task ||= Task.new
    end
    def host
      @host ||= Babushka::SystemSpec.for_host
    end
    def sources
      @sources ||= SourcePool.new
    end

    def run args
      if (task.verb = extract_verb(args)).nil?
        fail_with "Not sure what you meant."
      elsif host.nil?
        fail_with "This system is not supported."
      else
        parse_cmdline task.verb, args
        send "handle_#{task.verb.def.name}", task.verb
      end
    end


    private

    def extract_verb args
      if args.empty?
        fail_with handle_help
      elsif (verb = validate_verb(args.first)).nil?
        PassedVerb.new verb_for('meet'), [], []
      elsif verb != false
        args.shift
        PassedVerb.new verb_for(verb_abbrevs[verb]), [], []
      end
    end

    include Suggest::Helpers

    def validate_verb verb
      verb if verb.in? verb_abbrevs.keys
    end

    def parse_cmdline verb, args
      args.dup.each {|arg| parse_cmdline_token verb, args }
      fail_with "Unrecognised option: #{args.first}" unless args.empty?
    end

    def parse_cmdline_token verb, args
      if (detected_opt = verb.def.opts.detect {|o| args.first.in? [o.short, o.long] }).nil?
        verb.args = parse_cmdline_args(verb, verb.def.args, args)
      else
        args.shift
        verb.opts << parse_cmdline_opt(detected_opt, args)
      end
    end

    def parse_cmdline_opt opt_def, args
      returning PassedOpt.new(opt_def, []) do |parsed_opt|
        parsed_opt.args = parse_cmdline_args(parsed_opt, opt_def.args, args)
      end
    end

    def parse_cmdline_args token, arg_defs, args
      if token.args.length > 0
        # already parsed args
      elsif arg_defs.length > args.length
        fail_with "#{token.def.name} requires #{arg_defs.length} option#{'s' unless arg_defs.length == 1}, but #{args.length} #{args.length == 1 ? 'was' : 'were'} supplied."
      else
        arg_defs.map {|arg_def| PassedArg.new arg_def, args.shift }
      end
    end

    def help_for verb, error_message = nil
      help_verb = verb_for('help')
      handle_help PassedVerb.new(help_verb, [], [
        PassedArg.new(help_verb.args.detect {|arg| arg.name == :verb }, verb.name.to_s)
      ]), error_message
    end

    def print_version opts = {}
      if opts[:full]
        log "Babushka v#{Babushka::VERSION}, (c) 2009 Ben Hoskings <ben@hoskings.net>"
      else
        log Babushka::VERSION
      end
    end

    def print_usage
      log "\nThe gist:"
      log "  #{program_name} <command> [options]"
      log "\nAlso:"
      log "  #{program_name} help <command>  # #{verb_for('help').args.first.description}"
      log "  #{program_name} <dep name>      # A shortcut for 'babushka meet <dep name>'"
      log "  #{program_name} babushka        # Update babushka itself (what babushka.me/up does)"
    end

    def print_usage_for verb
      log "\n#{verb.name} - #{verb.description}"
      log "\nExample usage:"
      (verb.opts + verb.args).partition {|opt| !opt.optional }.tap {|items|
        items.first.each {|item| # mandatory
          log "  #{program_name} #{verb.name} #{describe_item item}"
        }
        unless items.last.empty? # optional
          log "  #{program_name} #{verb.name} #{items.last.map {|item| describe_item item }.join(' ')}"
        end
      }
    end

    def print_choices_for title, list
      log "\n#{title.capitalize}:"
      indent = (list.map {|item| printable_item(item).length }.max || 0) + 4
      list.each {|item|
        log "  #{printable_item(item).ljust(indent)}#{item.description}"
      }
    end

    def print_examples
      log "\nExamples:"
      log "  # Inspect the 'system' dep (and all its sub-deps) without touching the system.".colorize('grey')
      log "  #{program_name} system --dry-run"
      log "\n"
      log "  # Meet the 'fish' dep (i.e. install fish and all its dependencies).".colorize('grey')
      log "  #{program_name} fish"
      log "\n"
      log "  # Meet the 'user setup' dep, printing lots of debugging (including realtime".colorize('grey')
      log "  # shell command output).".colorize('grey')
      log "  #{program_name} 'user setup' --debug"
    end

    def print_notes
      log "\nCommands can be abbrev'ed, as long as they remain unique."
      log "  e.g. '#{program_name} l' is short for '#{program_name} list'."
    end

    def printable_item item
      if item.is_a? Verb
        item.name.to_s
      elsif item.is_a? Opt
        "#{[item.short, item.long].compact.join(', ')}"
      elsif item.is_a? Arg
        describe_item item
      end
    end

    def describe_item item
      item.is_a?(Opt) ? describe_option(item) : describe_arg(item)
    end

    def describe_option option
      opt_description = [
        option.short || option.long,
        option.args.map {|arg| describe_arg arg }
      ].squash.join(' ')
      "#{'[' if option.optional}#{opt_description}#{']' if option.optional}"
    end

    def describe_arg arg
      "#{arg.optional ? '[' : '<'}#{arg.name.to_s.gsub('_', ' ')}#{', ...' if arg.multi}#{arg.optional ? ']' : '>'}"
    end

    def verb_for verb_name
      Verbs.detect {|v| verb_name.in? [v.name.to_s, v.short, v.long].compact }
    end

    def all_verb_names
      Verbs.map {|v| [v.name.to_s, v.short, v.long] }.flatten.compact
    end

    require 'abbrev'
    def verb_abbrevs
      # Accept abbreviated verb names, but only accept full short & long options
      @verb_abbrevs ||= Verbs.map {|v|
        [v.short, v.long]
      }.inject(Verbs.map {|v| v.name.to_s }.abbrev) {|hsh,names|
        names.compact.each {|name| hsh[name] = name }
        hsh
      }
    end

    def fail_with message
      log message if message.is_a? String
      exit 1
    end

    def program_name
      @program_name ||= File.dirname($0).in?(ENV['PATH'].split(':')) ? File.basename($0) : $0
    end
  end
  end
end
