module Babushka
  class Base
  class << self

    # +task+ represents the overall job that is being run, and the parts that
    # are external to running the corresponding dep tree itself - logging, and
    # var loading and saving in particular.
    def task
      Task.instance
    end

    # +host+ is an instance of Babushka::SystemProfile for the system the command
    # was invoked on. If the current system isn't supported, SystemProfile.for_host
    # will return +nil+, and Base.run will fail early.
    def host
      @host ||= Babushka::SystemProfile.for_host
    end

    # +sources+ is an instance of Babushka::SourcePool, contains all the
    # sources that babushka can currently load deps from. This means all the sources
    # found in ~/.babushka/sources, plus the default sources:
    #   - anonymous (no source file; i.e. deps defined in an +irb+ session,
    #     or similar)
    #   - core (the builtin deps that babushka uses to install itself)
    #   - current dir (the contents of ./babushka-deps)
    #   - personal (the contents of ~/.babushka/deps)
    def sources
      SourcePool.instance
    end

    def threads
      @threads ||= []
    end

    def in_thread &block
      threads.push Thread.new(&block)
    end

    # The top-level entry point for babushka runs invoked at the command line.
    # When the `babushka` command is run, bin/babushka first triggers a load
    # via lib/babushka.rb, and then calls this method, passing in the
    # arguments that were passed on the command line.
    def run args
      if host.nil?
        fail_with "This system is not supported."
      elsif (task.verb = extract_verb(args)).nil?
        fail_with "Not sure what you meant."
      else
        parse_cmdline task.verb, args
        send "handle_#{task.verb.def.name}", task.verb
      end
    ensure
      Base.threads.each &:join
    end

    def exit_on_interrupt!
      if $stdin.tty?
        stty_save = `stty -g`.chomp
        trap("INT") {
          system "stty", stty_save
          unless Base.task.callstack.blank?
            puts "\n#{closing_log_message("#{Base.task.callstack.first.contextual_name} (cancelled)", false, :closing_status => true)}"
          end
          exit
        }
      end
    end

    def program_name
      @program_name ||= File.dirname($0).in?(ENV['PATH'].split(':')) ? File.basename($0) : $0
    end
  end
  end
end
