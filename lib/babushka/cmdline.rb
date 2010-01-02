module Babushka
  class Base
  class << self

    # Check structs.rb for the definitions of Verb, Opt and Arg.
    Verbs = [
      Verb.new(:version, nil, '--version', "Print the current version", [], []),
      Verb.new(:help, '-h', '--help', "Print usage information", [], [
        Arg.new(:verb, "Print command-specific usage info", true)
      ]),
      Verb.new(:update, nil, nil, "Update babushka itself", [
        Opt.new(:system, nil, '--system', "Update babushka itself to the latest version", false, [])
      ], []),
      Verb.new(:babushka, nil, nil, "An alias for 'update --system'", [], [
      ]),
      Verb.new(:list, '-T', '--tasks', "List the available deps", [], [
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
      Verb.new(:push, nil, nil, "Push dep updates you've made", [], [
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
    def handle_meet verb
      if (tasks = verb.args.map(&:value)).empty?
        fail_with "Nothing to do."
      else
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
    def handle_babushka verb
      load_deps_from core_dep_locations
      task.process 'babushka'
    end
    def handle_pull verb
      if verb.args.empty?
        Source.pull!
      else
        puts "'pull' doesn't accept any options."
      end
    end
    def handle_push verb
      fail_with "Push isn't implemented yet."
    end
    def handle_update verb
      if verb.opts.length != 1
        fail_with help_for verb.def, "'update' requires exactly one option."
      else
        Babushka.updater.update!
      end
    end

  end
  end
end
