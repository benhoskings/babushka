module Babushka
  VERSION = '0.1.1'

  class Base
  class << self
    Options = {
      :quiet => %w[-q --quiet],
      :debug => '--debug',
      :dry_run => %w[-n --dry-run],
      :defaults => %w[-y --defaults],
      :force => %w[-f --force]
    }.freeze
    OptionDescriptions = {
      :quiet => "Run with minimal logging",
      :debug => "Show more verbose logging, and realtime shell command output",
      :dry_run => "Discover the curent state without making any changes",
      :defaults => "Assume the default value for all vars without prompting, where possible",
      :force => "Attempt to meet the dependency even if it's already met"
    }.freeze

    def task
      @task ||= Task.new
    end

    def run args
      if usage(args)
        # nothing to do
      elsif !setup(args)
        fail_with "Error during load."
      elsif @tasks.empty?
        fail_with "Nothing to do."
      else
        @tasks.all? {|dep_name|
          task.process dep_name
        }
      end
    end

    def setup_noninteractive
      load_deps
    end


    private

    def usage args
      if !(args & %w[-h --help --halp]).empty?
        print_version :full => true
        print_usage
        print_options
        print_examples
        log "\n"
        true
      elsif !(args & %w[-V --version]).empty?
        print_version
        true
      end
    end

    def print_version opts = {}
      if opts[:full]
        log "Babushka v#{Babushka::VERSION}, (c) 2009 Ben Hoskings <ben@hoskings.net>"
      else
        log Babushka::VERSION
      end
    end

    def print_usage
      log "\nUsage:\n  ruby bin/babushka.rb [options] <dep name(s)>"
    end

    def print_options
      log "\nOptions:"
      indent = Options.values.map {|o| printable_option(o).length }.max + 4
      Options.each_pair {|name,option|
        log "  #{printable_option(option).ljust(indent)}#{OptionDescriptions[name]}"
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

    def setup args
      extract_opts(args).tap{|obj| debug "opts=#{obj.inspect}" }
      extract_vars(args).tap{|obj| debug "vars=#{obj.inspect}" }
      extract_tasks(args).tap{|obj| debug "tasks=#{obj.inspect}" }
      setup_noninteractive
    end

    def extract_opts args
      @opts = Options.inject({}) {|opts,(opt_name,opt_strings)|
        task.base_opts[opt_name] = opt_strings.any? {|opt| !args.extract! {|arg| arg == opt }.empty? }
        task.base_opts
      }
    end

    def extract_vars args
      args.extract! {|arg| arg['='] }.each {|arg|
        key, value = arg.split('=', 2)
        task.vars[key.to_sym].update :value => value, :from => :commandline
      }
      task.vars
    end

    def extract_tasks args
      @tasks = args
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
      log message
      exit 1
    end
  end
  end
end
