module Babushka
  class Base
  class << self

    # +task+ represents the overall job that is being run, and the parts that
    # are external to running the corresponding dep tree itself - logging, and
    # var loading and saving in particular.
    def task
      Task.instance
    end

    # +host+ is an instance of Babushka::SystemProfile for the system the command
    # was invoked on. If the current system isn't supported, SystemProfile.for_host
    # will return +nil+, and Base.run will fail early.
    def host
      @host ||= Babushka::SystemProfile.for_host
    end

    # +sources+ is an instance of Babushka::SourcePool, contains all the
    # sources that babushka can currently load deps from. This means all the sources
    # found in ~/.babushka/sources, plus the default sources:
    #   - anonymous (no source file; i.e. deps defined in an +irb+ session,
    #     or similar)
    #   - core (the builtin deps that babushka uses to install itself)
    #   - current dir (the contents of ./babushka-deps)
    #   - personal (the contents of ~/.babushka/deps)
    def sources
      SourcePool.instance
    end

    def threads
      @threads ||= []
    end

    def in_thread &block
      threads.push Thread.new(&block)
    end

    # The top-level entry point for babushka runs invoked at the command line.
    # When the `babushka` command is run, bin/babushka first triggers a load
    # via lib/babushka.rb, and then calls this method, passing in the
    # arguments that were passed on the command line.
    def run args
      if host.nil?
        fail_with "This system is not supported."
      elsif (task.verb = extract_verb(args)).nil?
        fail_with "Not sure what you meant."
      else
        parse_cmdline task.verb, args
        send "handle_#{task.verb.def.name}", task.verb
      end
    ensure
      Base.threads.each &:join
    end

    def exit_on_interrupt!
      if $stdin.tty?
        stty_save = `stty -g`.chomp
        trap("INT") {
          system "stty", stty_save
          unless Base.task.callstack.blank?
            puts "\n#{closing_log_message("#{Base.task.callstack.first.contextual_name} (cancelled)", false, :closing_status => true)}"
          end
          exit
        }
      end
    end


    private

    def extract_verb args
      if args.empty?
        fail_with handle_help
      elsif (verb = validate_verb(args.first)).nil?
        PassedVerb.new verb_for('meet'), [], [], {}
      elsif verb != false
        args.shift
        PassedVerb.new verb_for(verb_abbrevs[verb]), [], [], {}
      end
    end

    def validate_verb verb
      verb if verb.in? verb_abbrevs.keys
    end

    def parse_cmdline verb, args
      args.dup.each {|arg| parse_cmdline_token verb, args }
      fail_with "Unrecognised option: #{args.first}" unless args.empty?
    end

    def parse_cmdline_token verb, args
      detected_var = detect_var_in(args)
      if !detected_var.nil?
        args.shift
        verb.vars.update detected_var
      else
        detected_opt = detect_option_in(verb.def.opts, args) || detect_option_in(Opts, args)
        if !detected_opt.nil?
          args.shift
          verb.opts << parse_cmdline_opt(detected_opt, args)
        else
          verb.args = parse_cmdline_args(verb, verb.def.args, args)
        end
      end
    end

    def detect_var_in args
      detected_var = args.first.scan(/([a-z]\w+)\=(.*)/).flatten unless args.empty?
      {detected_var.first => {:value => detected_var.last}} unless detected_var.blank?
    end

    def detect_option_in opts, args
      opts.detect {|o| args.first.in? [o.short, o.long] }
    end

    def parse_cmdline_opt opt_def, args
      PassedOpt.new(opt_def, []).tap {|parsed_opt|
        parsed_opt.args = parse_cmdline_args(parsed_opt, opt_def.args, args)
      }
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
      ], {}), error_message
    end

    def print_version opts = {}
      if opts[:full]
        log "Babushka v#{Babushka::VERSION}, (c) 2011 Ben Hoskings <ben@hoskings.net>"
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

    def verb_abbrevs
      require 'abbrev'
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
