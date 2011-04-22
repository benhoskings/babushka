# -*- coding: utf-8 -*-

module Babushka
  class Base
  class << self

    # Check structs.rb for the definitions of Verb, Opt and Arg.
    Opts = [
      Opt.new(:debug, '-d', '--debug', "Show more verbose logging, and realtime shell command output", true, [])
    ]
    Verbs = [
      Verb.new(:meet, nil, nil, "The main one: run a dep and all its dependencies.", [
        Opt.new(:track_blocks, nil, '--track-blocks', "Track deps' blocks in TextMate as they're run", true, []),
        Opt.new(:dry_run, '-n', '--dry-run', "Discover the curent state without making any changes", true, []),
        Opt.new(:defaults, '-y', '--defaults', "Assume the default value for all vars without prompting, where possible", true, []),
        Opt.new(:force, '-f', '--force', "Attempt to meet the dependency even if it's already met", true, []),
        Opt.new(:no_color, '--no-color', '--no-colour', "Disable color in the output", true, [])
      ], [
        Arg.new(:dep_names, "The name of the dep to run", false, true)
      ]),
      Verb.new(:list, '-T', '--tasks', "List the available deps", [
        Opt.new(:templates, '-t', '--templates', "List templates instead of deps", true, [])
      ], [
        Arg.new(:filter, "Only list deps matching a substring", true, false, 'ruby')
      ]),
      Verb.new(:sources, nil, nil, "Manage dep sources", [
        Opt.new(:add, '-a', '--add', "Add dep source", false, [
          Arg.new(:name, "A name for this source", false, false, 'benhoskings'),
          Arg.new(:uri, "The URI of the source to add", false, false, 'git://github.com/benhoskings/babushka-deps')
        ]),
        Opt.new(:update, '-u', '--update', "Update all known sources", false, []),
        Opt.new(:list, '-l', '--list', "List dep sources", false, [])
      ], []),
      Verb.new(:console, nil, nil, "Start an interactive (irb-based) babushka session", [], []),
      Verb.new(:search, nil, nil, "Search for deps in the community database", [], [
        Arg.new(:q, "The keyword to search for", true, false, 'ruby')
      ]),
      Verb.new(:edit, nil, nil, "Load the file containing the specified dep in $EDITOR", [], [
        Arg.new(:name, "The name of the dep to load", true, false, 'ruby')
      ]),
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
      true
    end
    def handle_version verb
      print_version
      true
    end
    def handle_list verb
      to_list = verb.opts.empty? ? :deps : verb.opts.first.def.name
      filter_str = verb.args.first.value unless verb.args.first.nil?
      Base.sources.local_only {
        generate_list_for to_list, filter_str
      }
    end

    def handle_meet verb
      if (dep_names = verb.args.map(&:value)).empty?
        fail_with "Nothing to do."
      elsif Base.task.opt(:track_blocks) && !which('mate')
        fail_with "The --track-blocks option requires TextMate, and the `mate` helper.\nOn a Mac, you can install them like so:\n  babushka benhoskings:textmate"
      else
        task.process dep_names, verb.vars
      end
    end
    def handle_sources verb
      if verb.opts.empty?
        fail_with help_for(verb.def, "'sources' requires an option.")
      elsif verb.opts.first.def.name == :add
        args = verb.opts.first.args.map(&:value)
        begin
          Source.new(args.last, :name => args.first).add!
        rescue SourceError => ex
          log_error ex.message
        end
      elsif verb.opts.first.def.name == :update
        Base.sources.update!
      elsif verb.opts.first.def.name == :list
        Base.sources.list!
      end
    end

    def handle_console verb
      exec "irb -r'#{Path.lib / 'babushka'}' --simple-prompt"
    end

    def handle_search verb
      if verb.args.length != 1
        fail_with "'search' requires a single argument."
      else
        require 'net/http'
        require 'yaml'

        results = search_results_for(verb.args.first.value)

        if results.empty?
          log "Never seen a dep with '#{verb.args.first.value}' in its name."
        else
          log "The webservice knows about #{results.length} dep#{'s' unless results.length == 1} that match#{'es' if results.length == 1} '#{verb.args.first.value}':"
          log ""
          log_table(
            ['Name', 'Source', 'Runs', ' √', 'Command'],
            results
          )
          if (custom_sources = results.select {|r| r[1][github_autosource_regex].nil? }.count) > 0
            log ""
            log "✣  #{custom_sources == 1 ? 'This source has a custom URI' : 'These sources have custom URIs'}, so babushka can't discover #{custom_sources == 1 ? 'it' : 'them'} automatically."
            log "   You can run #{custom_sources == 1 ? 'its' : 'their'} deps in the same way, though, once you add #{custom_sources == 1 ? 'it' : 'them'} manually:"
            log "   $ #{program_name} sources -a <alias> <uri>"
            log "   $ #{program_name} <alias>:<dep>"
          end
        end
        !results.empty?
      end
    end

    def handle_edit verb
      if verb.args.length != 1
        fail_with "'edit' requires a single argument."
      elsif (dep = Dep.find_or_suggest(verb.args.first.value)).nil?
        fail_with "Can't find '#{verb.args.first.value}' to edit."
      elsif dep.load_path.nil?
        fail_with "Can't edit '#{dep.name}, since it wasn't loaded from a file."
      else
        file, line = dep.context.file_and_line
        editor_var = ENV['BABUSHKA_EDITOR'] || ENV['VISUAL'] || ENV['EDITOR'] || which('mate') || which('vim') || which('vi')
        case editor_var
        when /^mate/
          exec "mate -l#{line} '#{file}'"
        when /^vim?/, /^nano/, /^pico/, /^emacs/
          exec "#{editor_var} +#{line} '#{file}'"
        else
          exec "#{editor_var} '#{file}'"
        end
      end
    end

    private

    def search_results_for q
      YAML.load(search_webservice_for(q).body).sort_by {|i|
        -i[:runs_this_week]
      }.map {|i|
        [
          i[:name],
          i[:source_uri],
          ((i[:runs_this_week] && i[:runs_this_week] > 0) ? "#{i[:runs_this_week]} this week" : "#{i[:total_runs]} ever"),
          ((i[:runs_this_week] && i[:runs_this_week] > 0) ? "#{(i[:success_rate_this_week] * 100).round}%" : ((i[:total_runs] && i[:total_runs] > 0) ? "#{(i[:total_success_rate] * 100).round}%" : '')),
          (i[:source_uri][github_autosource_regex] ? "#{program_name} #{$1}:#{"'" if i[:name][/\s/]}#{i[:name]}#{"'" if i[:name][/\s/]}" : '✣')
        ]
      }
    end

    def github_autosource_regex
      /^git\:\/\/github\.com\/(.*)\/babushka-deps(\.git)?/
    end

    def search_webservice_for q
      Net::HTTP.start('babushka.me') {|http|
        http.get URI.encode("/deps/search.yaml/#{q}")
      }
    end

    def generate_list_for to_list, filter_str
      context = to_list == :deps ? program_name : ':template =>'
      Base.sources.all_present.each {|source|
        source.load!
      }.map {|source|
        [source, source.send(to_list).send(to_list)]
      }.map {|(source,items)|
        if filter_str.nil? || source.name[filter_str]
          [source, items]
        else
          [source, items.select {|item| item.name[filter_str] }]
        end
      }.select {|(source,items)|
        !items.empty?
      }.sort_by {|(source,items)|
        source.name
      }.each {|(source,items)|
        indent = (items.map {|item| "#{source.name}:#{item.name}".length }.max || 0) + 3
        log ""
        log "# #{source.name} (#{source.type})#{" - #{source.uri}" unless source.implicit?}"
        log "# #{items.length} #{to_list.to_s.chomp(items.length == 1 ? 's' : '')}#{" matching '#{filter_str}'" unless filter_str.nil?}:"
        items.each {|dep|
          log "#{context} #{"'#{source.name}:#{dep.name}'".ljust(indent)}"
        }
      }
    end
  end
  end
end
