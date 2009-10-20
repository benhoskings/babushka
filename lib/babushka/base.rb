module Babushka
  VERSION = '0.1.1'

  class Base
  class << self
    Verbs = [
      Verb.new(:version, "Print the current version", [], []),
      Verb.new(:help, "Print usage information", [], [
        Arg.new(:verb, "Print verb-specific usage info", true)
      ]),
      Verb.new(:sources, "Manage dep sources", [
        Opt.new(:add, '-a', '--add', "Add dep source", false, [
          Arg.new(:source_uri, "the URI of the source to add", false, false, 'git://github.com/benhoskings/babushka_deps')
        ]),
        Opt.new(:list, '-l', '--list', "List dep sources", false, []),
        Opt.new(:remove, '-r', '--remove', "Remove dep source", false, [
          Arg.new(:source_uri, "the URI of the soure to remove", false, false, 'git://github.com/benhoskings/babushka_deps')
        ]),
        Opt.new(:clear, '-c', '--clear', "Remove all dep sources", false, [])
      ], []),
      Verb.new(:pull, "Update dep sources", [], [
        Arg.new(:source, "Pull just a specific source", true, false)
      ]),
      Verb.new(:push, "Push local dep updates to writable sources", [], [
        Arg.new(:source, "Push just a specific source", true, false)
      ]),
      Verb.new(:meet, "Process deps", [
        Opt.new(:quiet, '-q', '--quiet', "Run with minimal logging", true, []),
        Opt.new(:debug, '-d', '--debug', "Show more verbose logging, and realtime shell command output", true, []),
        Opt.new(:dry_run, '-n', '--dry-run', "Discover the curent state without making any changes", true, []),
        Opt.new(:defaults, '-y', '--defaults', "Assume the default value for all vars without prompting, where possible", true, []),
        Opt.new(:force, '-f', '--force', "Attempt to meet the dependency even if it's already met", true, [])
      ], [
        Arg.new(:dep_names, "The names of the deps that should be processed", false, true)
      ])
    ]

    def task
      @task ||= Task.new
    end

    def host
      @host ||= Babushka::SystemSpec.for_system
    end

    def run args
      if (task.verb = extract_verb(args)).nil?
        fail_with "Not sure what you meant."
      else
        parse_cmdline task.verb, args
        send "handle_#{task.verb.def.name}", task.verb
      end
    end

    def setup_noninteractive
      load_deps
    end


    private

    def extract_verb args
      if (verb = args.shift).nil?
        fail_with handle_help args
      else
        verb = verb.dup.gsub /^-*/, ''
        if !verb.in?(abbrevs.keys)
          fail_with "'#{verb}' isn't a valid verb. Maybe you meant 'meet #{verb}'?"
        else
          PassedVerb.new verb_for(abbrevs[verb]), [], []
        end
      end
    end

    def parse_cmdline verb, args
      args.dup.each {|arg| parse_cmdline_token verb, args }
      fail_with "Unrecognised option: #{args.first}" unless args.empty?
    end

    def parse_cmdline_token verb, args
      if (detected_opt = verb.def.opts.detect {|o| args.first.in? [o.short, o.long] }).nil?
        verb.args = parse_cmdline_args(verb, verb.def.args, args)
      else
        verb.opts << parse_cmdline_opt(args.shift, detected_opt, args)
      end
    end

    def parse_cmdline_opt opt, opt_def, args
      PassedOpt.new opt_def, parse_cmdline_args(opt_def, opt_def.args, args)
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

    def handle_help verb
      print_version :full => true
      if (help_arg = verb.args.first).nil?
        print_usage
        print_choices_for 'verbs', Verbs
      elsif (help_verb = verb_for(help_arg.value)).nil?
        log "#{help_arg.value.capitalize}? I have honestly never heard of that."
      else
        print_usage_for help_verb
        print_choices_for 'options', help_verb.opts
      end
      log "\n"
    end
    def handle_version verb
      print_version
    end
    def handle_meet verb
      if (tasks = verb.args.map(&:value)).empty?
        fail_with "Nothing to do."
      else
        setup_noninteractive
        tasks.all? {|dep_name| task.process dep_name }
      end
    end
    def handle_sources verb
      puts 'sources lol'
    end
    def handle_pull verb
      puts 'pull lol'
    end
    def handle_push verb
      puts 'push lol'
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
      log "  babushka <verb> [options]"
      log "  babushka <dep name(s)>     # A shortcut for 'meet <dep name(s)>'"
    end

    def print_usage_for verb
      log "\nExample usage:"
      (verb.opts + verb.args).partition {|opt| !opt.optional }.tap {|opts|
        opts.first.each {|opt|
          log "  babushka #{verb.name} #{describe_option opt}"
        }
        unless opts.last.empty?
          log "  babushka #{verb.name} #{opts.last.map {|o| describe_option o }.join(' ')}"
        end
      }
    end

    def print_choices_for title, list
      log "\n#{title.capitalize}:"
      indent = (list.map {|option| printable_option(option).length }.max || 0) + 4
      list.each {|option|
        log "  #{printable_option(option).ljust(indent)}#{option.description}"
      }
    end

    def print_examples
      log "\nExamples:"
      log "  # Inspect the 'system' dep (and all its sub-deps) without touching the system.".colorize('grey')
      log "  babushka system --dry-run"
      log "\n"
      log "  # Meet the 'fish' dep (i.e. install fish and all its dependencies).".colorize('grey')
      log "  babushka fish"
      log "\n"
      log "  # Meet the 'user setup' dep, printing lots of debugging (including realtime".colorize('grey')
      log "  # shell command output).".colorize('grey')
      log "  babushka 'user setup' --debug"
    end

    def printable_option option
      option.is_a?(Verb) ? option.name : "#{[option.short, option.long].join(', ')}"
    end

    def describe_option option
      opt_description = [
        option.short || option.long,
        option.args.map {|arg| "#{arg.optional ? '[' : '<'}#{arg.name}#{', ...' if arg.multi}#{arg.optional ? ']' : '>'}" }
      ].squash.join(' ')
      "#{'[' if option.optional}#{opt_description}#{']' if option.optional}"
    end

    def verb_for verb_name
      Verbs.detect {|v| v.name.to_s == verb_name }
    end

    require 'abbrev'
    def abbrevs
      Verbs.map {|v| v.name.to_s }.abbrev
    end

    def load_deps
      %W[
        ./babushka_deps
        ~/.babushka/deps
        #{File.dirname(File.dirname(real_bin_babushka)) / 'deps'}
      ].all? {|dep_path|
        DepDefiner.load_deps_from dep_path
      }
    end

    def fail_with message
      log message if message.is_a? String
      exit 1
    end
  end
  end
end
