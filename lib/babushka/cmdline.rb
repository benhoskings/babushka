# coding: utf-8

module Babushka
  class Cmdline

    handle('global', "Options that are valid for any handler") {
      opt '-v', '--version',     "Print the current version"
      opt '-h', '--help',        "Show this information"
      opt '-d', '--debug',       "Show more verbose logging, and realtime shell command output"
      opt '-s', '--silent',      "Only log errors, running silently on success"
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
        LogHelpers.log "#{cmd.argv.first.capitalize}? I have honestly never heard of that."
      else
        LogHelpers.log "\n#{handler.name} - #{handler.description}"
        cmd.parse(&handler.opt_definer)
        cmd.print_usage
      end
      LogHelpers.log "\n"
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
      opt '-n', '--dry-run',      "Check which deps are met, but don't meet any unmet deps"
      opt '-y', '--defaults',     "Use dep arguments' default values without prompting"
      opt '-u', '--update',       "Update sources before loading deps from them"
      opt       '--show-args',    "Show the arguments being passed between deps as they're run"
      opt       '--profile',      "Print a per-line timestamp to the debug log"
    }.run {|cmd|
      dep_names, args = cmd.argv.partition {|arg| arg['='].nil? }
      if !(bad_arg = args.detect {|arg| arg[/^\w+=/].nil? }).nil?
        LogHelpers.log_error "'#{bad_arg}' looks like a dep argument, but it doesn't make sense."
      elsif dep_names.empty?
        LogHelpers.log_error "Nothing to do."
      else
        hashed_args = args.map {|i|
          i.split('=', 2)
        }.inject({}) {|hsh,i|
          hsh[i.first] = i.last
          hsh
        }
        Base.task.process(dep_names, hashed_args, cmd)
      end
    }

    handle('sources', "Manage dep sources") {
      opt '-a', '--add NAME URI', "Add the source at URI as NAME"
      opt '-u', '--update',       "Update all known sources from their remotes"
      opt '-l', '--list',         "List dep sources that are present locally"
    }.run {|cmd|
      if cmd.opts.slice(:add, :update, :list).length != 1
        LogHelpers.log_error "'sources' requires a single option."
      elsif cmd.opts.has_key?(:add)
        if cmd.argv.length != 1
          LogHelpers.log_error "The -a option requires a URI as its second argument. `babushka sources --help` for more info."
        else
          begin
            Source.new(nil, cmd.opts[:add], cmd.argv.first).add!
          rescue SourceError => e
            LogHelpers.log_error e.message
          end
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

    handle('edit', "Load the file containing the specified dep in $EDITOR").run {|cmd|
      if cmd.argv.length != 1
        LogHelpers.log_error "'edit' requires a single argument."
      else
        Base.sources.find_or_suggest(cmd.argv.first) {|dep|
          if dep.load_path.nil?
            LogHelpers.log_error "Can't edit '#{dep.name}', since it wasn't loaded from a file."
          else
            file, line = dep.context.source_location
            editor_var = ENV['BABUSHKA_EDITOR'] || ENV['VISUAL'] || ENV['EDITOR'] || ShellHelpers.which('subl') || ShellHelpers.which('mate') || ShellHelpers.which('vim') || ShellHelpers.which('vi')
            case editor_var
            when /^subl/
              exec "subl -n '#{file}':#{line}"
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
    }

  end
end
