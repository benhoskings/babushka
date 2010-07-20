module Babushka
  class Base
  class << self

    # Check structs.rb for the definitions of Verb, Opt and Arg.
    Verbs = [
      Verb.new(:meet, nil, nil, "The main one: run a dep and all its dependencies.", [
        Opt.new(:quiet, '-q', '--quiet', "Run with minimal logging", true, []),
        Opt.new(:debug, '-d', '--debug', "Show more verbose logging, and realtime shell command output", true, []),
        Opt.new(:track_blocks, nil, '--track-blocks', "Track deps' blocks in TextMate as they're run", true, []),
        Opt.new(:dry_run, '-n', '--dry-run', "Discover the curent state without making any changes", true, []),
        Opt.new(:defaults, '-y', '--defaults', "Assume the default value for all vars without prompting, where possible", true, []),
        Opt.new(:force, '-f', '--force', "Attempt to meet the dependency even if it's already met", true, [])
      ], [
        Arg.new(:dep_names, "The name of the dep to run", false, true)
      ]),
      Verb.new(:list, '-T', '--tasks', "List the available deps", [], [
        Arg.new(:filter, "Only list deps matching a substring", true, false, 'ruby')
      ]),
      Verb.new(:sources, nil, nil, "Manage dep sources", [
        Opt.new(:add, '-a', '--add', "Add dep source", false, [
          Arg.new(:name, "A name for this source", false, false, 'benhoskings'),
          Arg.new(:uri, "The URI of the source to add", false, false, 'git://github.com/benhoskings/babushka_deps')
        ]),
        Opt.new(:list, '-l', '--list', "List dep sources", false, [])
      ], []),
      Verb.new(:help, '-h', '--help', "Print usage information", [], [
        Arg.new(:verb, "Print command-specific usage info", true)
      ]),
      Verb.new(:version, nil, '--version', "Print the current version", [], [])
    ]

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
      filter_str = verb.args.first.value unless verb.args.first.nil?
      Dep.pool.deps.select {|dep|
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

    include Shell::Helpers
    def handle_meet verb
      if (tasks = verb.args.map(&:value)).empty?
        fail_with "Nothing to do."
      elsif Base.task.opt(:track_blocks) && !which('mate')
        fail_with "The --track-blocks option requires TextMate, and the `mate` helper.\nOn a Mac, you can install them like so:\n  babushka benhoskings/textmate"
      else
        tasks.all? {|dep_name| task.process dep_name }
      end
    end
    def handle_sources verb
      if verb.opts.length != 1
        fail_with help_for(verb.def, "'sources' requires exactly one option.")
      elsif verb.opts.first.def.name == :add
        args = verb.opts.first.args.map(&:value)
        begin
          Source.new(args.last, :name => args.first).add!
        rescue SourceError => ex
          log_error ex.message
        end
      elsif verb.opts.first.def.name == :list
        Base.sources.list!
      end
    end
  end
  end
end
