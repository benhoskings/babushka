module Babushka
  VERSION = '0.1.1'

  class Base
  class << self
    def self.opt name, short, long, description, arg_hash = {}
      Opt.new name, short, long, description, arg_hash.keys.map {|arg_name|
        Arg.new arg_name, arg_hash[arg_name], false
      }
    end
    Verbs = [
      Verb.new('version', "Print the current version"),
      Verb.new('help', "Print usage information", [
        Arg.new('verb', "Print verb-specific usage info", true)
      ]),
      Verb.new('sources', "Manage dep sources", [
        opt('add', '-a', '--add', "Add dep source", {:source_uri => "the URI of the source to add"}),
        opt('list', '-l', '--list', "List dep sources"),
        opt('remove', '-r', '--remove', "Remove dep source", {:source_uri => "the URI of the soure to remove"}),
        opt('clear', '-c', '--clear', "Remove all dep sources")
      ]),
      Verb.new('pull', "Update dep sources", [
        Arg.new('source', "Pull just a specific source", true)
      ]),
      Verb.new('push', "Push local dep updates to writable sources", [
        Arg.new('source', "Push just a specific source", true)
      ]),
      Verb.new('meet', "Process deps", [
        opt('quiet', '-q', '--quiet', "Run with minimal logging"),
        opt('debug', '-d', '--debug', "Show more verbose logging, and realtime shell command output"),
        opt('dry run', '-n', '--dry-run', "Discover the curent state without making any changes"),
        opt('defaults', '-y', '--defaults', "Assume the default value for all vars without prompting, where possible"),
        opt('force', '-f', '--force', "Attempt to meet the dependency even if it's already met")
      ])
    ]

    def task
      @task ||= Task.new
    end

    def host
      @host ||= Babushka::SystemSpec.for_system
    end

    def run args
      if !extract_verb(args)
        fail_with "Not sure what you meant."
      else
        send "handle_#{@verb.name}", args
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
          fail_with "'#{verb}' isn't a valid verb. Maybe you meant 'install #{verb}'?"
        else
          @verb = verb_for abbrevs[verb]
        end
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
        print_usage_for 'options', verb.opts
        # print_examples_for @verb
      end
      log "\n"
    end
    def handle_version args
      print_version
    end
    def handle_meet args
      if !setup(ARGV)
        fail_with "Error during load."
      elsif @tasks.empty?
        fail_with "Nothing to do."
      else
        @tasks.all? {|dep_name| task.process dep_name }
      end
    end
    def handle_sources args
      puts 'sources lol'
    end
    def handle_pull args
      puts 'pull lol'
    end
    def handle_push args
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
