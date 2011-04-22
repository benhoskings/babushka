# -*- coding: utf-8 -*-

module Babushka
  module Cmdline

    handle('global', "Options that are valid for any handler") {
      opt '-v', '--version',                 "Print the current version"
      opt '-h', '--help',                    "Show this information"
      opt '-d', '--debug',                   "Show more verbose logging, and realtime shell command output"
      opt       '--no-color', '--no-colour', "Disable color in the output"
    }

    handle('help', "Print usage information").run {|cmd|
      Helpers.print_version :full => true
      if cmd.argv.empty?
        Helpers.print_usage
        Helpers.print_handlers
        Helpers.print_notes
      elsif (handler = Handler.for(cmd.argv.first)).nil?
        log "#{cmd.argv.first.capitalize}? I have honestly never heard of that."
      else
        log "\n#{handler.name} - #{handler.description}"
        Base.task.cmdline.parse &handler.opt_definer
        Base.task.cmdline.print_usage
      end
      log "\n"
      true
    }

    handle('version', "Print the current version").run {
      Helpers.print_version
      true
    }

    handle('list', "List the available deps") {
      opt '-t', '--templates', "List templates instead of deps"
    }.run {|cmd|
      Base.sources.local_only {
        Helpers.generate_list_for(cmd.opts[:templates] ? :templates : :deps, cmd.argv.first)
      }
    }

    handle('meet', 'The main one: run a dep and all its dependencies.') {
      opt '-n', '--dry-run',      "Discover the curent state without making any changes"
      opt '-y', '--defaults',     "Assume the default value for all vars without prompting, where possible"
      opt       '--track-blocks', "Track deps' blocks in TextMate as they're run"
    }.run {|cmd|
      dep_names, vars = cmd.argv.partition {|arg| arg['='].nil? }
      if dep_names.blank?
        fail_with "Nothing to do."
      elsif cmd.opts[:track_blocks] && !which('mate')
        fail_with "The --track-blocks option requires TextMate, and the `mate` helper.\nOn a Mac, you can install them like so:\n  babushka benhoskings:textmate"
      else
        Base.task.process dep_names, Hash[vars.map {|i| i.split('=', 2) }]
      end
    }

    handle('sources', "Manage dep sources") {
      opt '-a', '--add NAME URI', "Add the source at URI as NAME"
      opt '-u', '--update',       "Update all known sources"
      opt '-l', '--list',         "List dep sources"
    }.run {|uri|
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
    }

    handle('console', "Start an interactive (irb-based) babushka session").run {
      exec "irb -r'#{Path.lib / 'babushka'}' --simple-prompt"
    }

    handle('search', "Search for deps in the community database").run {
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
    }

    handle('edit', "Load the file containing the specified dep in $EDITOR").run {
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
    }
  end
end
