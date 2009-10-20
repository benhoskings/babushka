module Babushka
  VERSION = '0.1.1'

  class Base
  class << self
    Verbs = [
      Verb.new('version', "Print the current version", [], []),
      Verb.new('help', "Print usage information", [], [
        Arg.new('verb', "Print verb-specific usage info", true)
      ]),
      Verb.new('sources', "Manage dep sources", [
        Opt.new('add', '-a', '--add', "Add dep source", [
          Arg.new('source_uri', "the URI of the source to add", false)
        ]),
        Opt.new('list', '-l', '--list', "List dep sources", []),
        Opt.new('remove', '-r', '--remove', "Remove dep source", [
          Arg.new('source_uri', "the URI of the soure to remove", false)
        ]),
        Opt.new('clear', '-c', '--clear', "Remove all dep sources", [])
      ], []),
      Verb.new('pull', "Update dep sources", [], [
        Arg.new('source', "Pull just a specific source", true)
      ]),
      Verb.new('push', "Push local dep updates to writable sources", [], [
        Arg.new('source', "Push just a specific source", true)
      ]),
      Verb.new('meet', "Process deps", [
        Opt.new('quiet', '-q', '--quiet', "Run with minimal logging", []),
        Opt.new('debug', '-d', '--debug', "Show more verbose logging, and realtime shell command output", []),
        Opt.new('dry run', '-n', '--dry-run', "Discover the curent state without making any changes", []),
        Opt.new('defaults', '-y', '--defaults', "Assume the default value for all vars without prompting, where possible", []),
        Opt.new('force', '-f', '--force', "Attempt to meet the dependency even if it's already met", [])
      ], [
        Arg.new('dep names', "The names of the deps that should be processed", false, true)
      ])
    ]

    def task
      @task ||= Task.new
    end

    def host
      @host ||= Babushka::SystemSpec.for_system
    end

    def run args
      if (verb = extract_verb(args)).nil?
        fail_with "Not sure what you meant."
      else
        parse_cmdline verb, args
        send "handle_#{verb.def.name}", verb
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
      args.each {|arg| parse_cmdline_token verb, args }
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
      PassedOpt.new opt_def, parse_cmdline_args(opt, opt_def.args, args)
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

    def handle_help args
      print_version :full => true
      if (verb_name = args.first).nil?
        print_usage
        print_usage_for 'verbs', Verbs
      elsif (verb = verb_for(verb_name)).nil?
        log "No help for that."
      else
        print_usage
        print_usage_for 'options', verb.opts
        # print_examples_for verb
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
      log "\nUsage:"
      log "  babushka <verb> [options]"
      log "  babushka <dep name(s)>     # A shortcut for 'meet <dep name(s)>'"
    end

    def print_usage_for title, list
      log "\n#{title.capitalize}:"
      indent = list.map {|option| printable_option(option.name).length }.max + 4
      list.each {|option|
        log "  #{printable_option(option.name).ljust(indent)}#{option.description}"
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
      [*option].join(', ')
    end

    def verb_for verb_name
      Verbs.detect {|v| v.name == verb_name }
    end

    require 'abbrev'
    def abbrevs
      Verbs.map(&:name).abbrev
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
