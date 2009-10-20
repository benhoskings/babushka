module Babushka
  VERSION = '0.1.1'

  class Base
  class << self
    Verbs = [
      Verb.new(:version, "Print the current version", [], []),
      Verb.new(:help, "Print usage information", [], [
        Arg.new(:verb, "Print verb-specific usage info", true)
      ]),
      Verb.new(:list, "List the available deps", [
        # Opt.new(:source, '-s', '--source', "Only list deps from a specific source", true, [
        #   Arg.new(:name, "The name of the source", false, false, 'git://github.com/benhoskings/babushka_deps')
        # ])
      ], [
        Arg.new(:filter, "Only list deps matching a substring", true, false, 'ruby')
      ]),
=begin
      Verb.new(:sources, "Manage dep sources", [
        Opt.new(:add, '-a', '--add', "Add dep source", false, [
          Arg.new(:uri, "The URI of the source to add", false, false, 'git://github.com/benhoskings/babushka_deps')
        ]),
        Opt.new(:list, '-l', '--list', "List dep sources", false, []),
        Opt.new(:remove, '-r', '--remove', "Remove dep source", false, [
          Arg.new(:uri, "The URI of the soure to remove", false, false, 'git://github.com/benhoskings/babushka_deps')
        ]),
        Opt.new(:clear, '-c', '--clear', "Remove all dep sources", false, [])
      ], []),
      Verb.new(:pull, "Update dep sources", [], [
        Arg.new(:source, "Pull just a specific source", true, false)
      ]),
      Verb.new(:push, "Push local dep updates to writable sources", [], [
        Arg.new(:source, "Push just a specific source", true, false)
      ]),
=end
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
        fail_with handle_help
      else
        verb = verb.dup.gsub /^-*/, ''
        if !verb.in?(abbrevs.keys)
          fail_with "#{$0} meet '#{verb}'    # '#{verb}' isn't a command - maybe you meant this instead."
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

    def handle_help verb = nil
      print_version :full => true
      if verb.nil? || (help_arg = verb.args.first).nil?
        print_usage
        print_choices_for 'commands', Verbs
        print_notes
      elsif (help_verb = verb_for(help_arg.value)).nil?
        log "#{help_arg.value.capitalize}? I have honestly never heard of that."
      else
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
        deps.each {|dep|
          log "#{$0} #{"'#{dep.name}'".ljust(indent)} #{"# #{dep.desc}" unless dep.desc.blank?}"
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
      log "  #{$0} <command> [options]"
      log "\nAlso:"
      log "  #{$0} help <command>  # #{verb_for('help').args.first.description}"
      log "  #{$0} <dep name(s)>   # A shortcut for 'meet <dep name(s)>'"
    end

    def print_usage_for verb
      log "\nExample usage:"
      (verb.opts + verb.args).partition {|opt| !opt.optional }.tap {|items|
        items.first.each {|item| # mandatory
          log "  #{$0} #{verb.name} #{describe_item item}"
        }
        unless items.last.empty? # optional
          log "  #{$0} #{verb.name} #{items.last.map {|item| describe_item item }.join(' ')}"
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
      log "  #{$0} system --dry-run"
      log "\n"
      log "  # Meet the 'fish' dep (i.e. install fish and all its dependencies).".colorize('grey')
      log "  #{$0} fish"
      log "\n"
      log "  # Meet the 'user setup' dep, printing lots of debugging (including realtime".colorize('grey')
      log "  # shell command output).".colorize('grey')
      log "  #{$0} 'user setup' --debug"
    end

    def print_notes
      log "\nCommands can be abbrev'ed, as long as they remain unique."
      log "e.g. '#{$0} l' is short for '#{$0} list'."
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
