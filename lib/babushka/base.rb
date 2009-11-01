module Babushka
  VERSION = '0.1.1'

  class Base
  class << self
    Verbs = [
      Verb.new(:version, nil, '--version', "Print the current version", [], []),
      Verb.new(:help, '-h', '--help', "Print usage information", [], [
        Arg.new(:verb, "Print command-specific usage info", true)
      ]),
      Verb.new(:list, '-T', '--tasks', "List the available deps", [
        # Opt.new(:source, '-s', '--source', "Only list deps from a specific source", true, [
        #   Arg.new(:name, "The name of the source", false, false, 'git://github.com/benhoskings/babushka_deps')
        # ])
      ], [
        Arg.new(:filter, "Only list deps matching a substring", true, false, 'ruby')
      ]),
      Verb.new(:sources, nil, nil, "Manage dep sources", [
        Opt.new(:add, '-a', '--add', "Add dep source", false, [
          Arg.new(:name, "A name for this source", false, false, 'benhoskings'),
          Arg.new(:uri, "The URI of the source to add", false, false, 'git://github.com/benhoskings/babushka_deps')
        ]),
        Opt.new(:list, '-l', '--list', "List dep sources", false, []),
        Opt.new(:remove, '-r', '--remove', "Remove dep source", false, [
          Arg.new(:name_or_uri, "The name or URI of the source to remove", false, false, 'benhoskings')
        ]),
        Opt.new(:clear, '-c', '--clear', "Remove all dep sources", false, [])
      ], []),
      Verb.new(:pull, nil, nil, "Update dep sources", [], [
        Arg.new(:source, "Pull just a specific source", true, false)
      ]),
      Verb.new(:push, nil, nil, "Push local dep updates to writable sources", [], [
        Arg.new(:source, "Push just a specific source", true, false)
      ]),
      Verb.new(:meet, nil, nil, "Process deps", [
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
      if args.empty?
        fail_with handle_help
      elsif (verb = validate_verb(args.first)).nil?
        confirm %Q{That's not a verb - did you mean "meet '#{args.first}'"?}, :default => 'y' do
          PassedVerb.new verb_for('meet'), [], []
        end
      else
        args.shift
        PassedVerb.new verb_for(verb_abbrevs[verb]), [], []
      end
    end

    include SuggestHelpers

    def validate_verb verb
      if verb.in? verb_abbrevs.keys
        verb # it's a properly spelled verb
      else
        suggest_value_for(verb, all_verb_names)
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
        args.shift
        verb.opts << parse_cmdline_opt(detected_opt, args)
      end
    end

    def parse_cmdline_opt opt_def, args
      returning PassedOpt.new opt_def, [] do |parsed_opt|
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

    def handle_help verb = nil, error_message = nil
      print_version :full => true
      if verb.nil? || (help_arg = verb.args.first).nil?
        print_usage
        print_choices_for 'commands', Verbs
        print_notes
      elsif (help_verb = verb_for(help_arg.value)).nil?
        log "#{help_arg.value.capitalize}? I have honestly never heard of that."
      else
        log_error error_message unless error_message.nil?
        print_usage_for help_verb
        print_choices_for 'options', (help_verb.opts + help_verb.args)
      end
      log "\n"
    end
    def handle_version verb
      print_version
    end
    def handle_list verb
      setup_noninteractive
      filter_str = verb.args.first.value unless verb.args.first.nil?
      Dep.deps.values.select {|dep|
        filter_str.nil? || dep.name[filter_str]
      }.sort_by {|dep|
        dep.name
      }.tap {|deps|
        indent = (deps.map {|dep| dep.name.length }.max || 0) + 3
        log ""
        deps.each {|dep|
          log "#{program_name} #{"'#{dep.name}'".ljust(indent)} #{"# #{dep.desc}" unless dep.desc.blank?}"
        }
      }
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
      if verb.opts.length != 1
        fail_with help_for verb.def, "'sources' requires exactly one option."
      else
        Source.send "#{verb.opts.first.def.name}!", *verb.opts.first.args.map(&:value)
      end
    end
    def handle_pull verb
      if verb.args.empty?
        Source.pull!
      else
        puts 'fail'
      end
    end
    def handle_push verb
      fail_with "Push isn't implemented yet."
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
      log "  #{program_name} <dep name(s)>   # A shortcut for 'meet <dep name(s)>'"
    end

    def print_usage_for verb
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
      log "e.g. '#{program_name} l' is short for '#{program_name} list'."
    end

    def printable_item item
      if item.is_a? Verb
        item.name.to_s
      elsif item.is_a? Opt
        "#{[item.short, item.long].join(', ')}"
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

    def load_deps
      [
        './babushka_deps', # deps in the current directory
        '~/.babushka/deps', # the user's custom deps
      ].concat(
        Source.paths # each dep source
      ).push(
        Path.path / 'deps' # the bundled deps
      ).all? {|dep_path|
        DepDefiner.load_deps_from dep_path
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
