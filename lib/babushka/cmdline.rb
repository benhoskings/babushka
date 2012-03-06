# coding: utf-8

module Babushka
  module Cmdline
    extend LogHelpers

    handle('global', "Options that are valid for any handler") {
      opt '-v', '--version',     "Print the current version"
      opt '-h', '--help',        "Show this information"
      opt '-d', '--debug',       "Show more verbose logging, and realtime shell command output"
      opt       '--[no-]color',
                '--[no-]colour', "Disable color in the output"
    }

    handle('help', "Print usage information").run {|cmd|
      Helpers.print_version :full => true
      if cmd.argv.empty?
        Helpers.print_usage
        Helpers.print_handlers
        Helpers.print_notes
      elsif (handler = Handler.for(cmd.argv.first)).nil?
        Helpers.log "#{cmd.argv.first.capitalize}? I have honestly never heard of that."
      else
        Helpers.log "\n#{handler.name} - #{handler.description}"
        cmd.parse(&handler.opt_definer)
        cmd.print_usage
      end
      Helpers.log "\n"
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
      opt '-u', '--update',       "Update referenced sources before loading deps from them"
      opt       '--show-args',    "Show the arguments being passed between deps as they're run"
      opt       '--track-blocks', "Track deps' blocks in TextMate as they're run"
    }.run {|cmd|
      dep_names, vars = cmd.argv.partition {|arg| arg['='].nil? }
      if !(bad_var = vars.detect {|var| var[/^\w+=/].nil? }).nil?
        fail_with "'#{bad_var}' looks like a var but it doesn't make sense."
      elsif dep_names.empty?
        fail_with "Nothing to do."
      elsif cmd.opts[:track_blocks] && !which('mate')
        fail_with "The --track-blocks option requires TextMate, and the `mate` helper.\nOn a Mac, you can install them like so:\n  babushka benhoskings:textmate"
      else
        Base.task.process dep_names, vars.map {|i|
          i.split('=', 2)
        }.inject({}) {|hsh,i|
          hsh[i.first] = i.last
          hsh
        }
      end
    }

    handle('sources', "Manage dep sources") {
      opt '-a', '--add NAME URI', "Add the source at URI as NAME"
      opt '-u', '--update',       "Update all known sources"
      opt '-l', '--list',         "List dep sources"
    }.run {|cmd|
      if cmd.opts.slice(:add, :update, :list).length != 1
        fail_with "'sources' requires a single option."
      elsif cmd.opts.has_key?(:add)
        begin
          Source.new(cmd.argv.first, :name => cmd.opts[:add]).add!
        rescue SourceError => e
          log_error e.message
        end
      elsif cmd.opts.has_key?(:update)
        Base.sources.update!
      elsif cmd.opts.has_key?(:list)
        Base.sources.list!
      end
    }

    handle('console', "Start an interactive (irb-based) babushka session").run {
      exec "irb -r'#{Path.lib / 'babushka'}' --simple-prompt"
    }

    handle('search', "Search for deps in the community database").run {|cmd|
      if cmd.argv.length != 1
        fail_with "'search' requires a single argument."
      else
        require 'net/http'
        require 'yaml'

        search_term = cmd.argv.first
        results = Helpers.search_results_for(search_term)

        if results.empty?
          log "Never seen a dep with '#{search_term}' in its name."
        else
          Helpers.print_search_results search_term, results
          true
        end
      end
    }

    handle('edit', "Load the file containing the specified dep in $EDITOR").run {|cmd|
      if cmd.argv.length != 1
        fail_with "'edit' requires a single argument."
      elsif (dep = Dep.find_or_suggest(cmd.argv.first)).nil?
        fail_with "Can't find '#{cmd.argv.first}' to edit."
      elsif dep.load_path.nil?
        fail_with "Can't edit '#{dep.name}, since it wasn't loaded from a file."
      else
        file, line = dep.context.source_location
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
