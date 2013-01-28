module Babushka

  # +host+ is an instance of Babushka::SystemProfile for the system the command
  # was invoked on.
  # If the current system isn't supported, SystemProfile.for_host will return
  # +nil+, and Base.run will fail early. If the system is known but the
  # flavour isn't (e.g. an unknown Linux variant), a generic SystemProfile
  # will be used, which should work for most operations but will fail on deps
  # that attempt to use the package manager, etc.
  def host
    @host ||= Babushka::SystemDetector.profile_for_host
  end
  module_function :host

  def ruby
    @ruby ||= Babushka::CurrentRuby.new
  end
  module_function :ruby

  class Base
  class << self

    # The time at which babushka was loaded. This is used in LogHelpers to
    # print profiling information via the '--profile' commandline option.
    @@start_time = Time.now
    def start_time
      @@start_time
    end

    # +task+ represents the overall job that is being run, and things that
    # are external to running the corresponding dep tree itself, like logging.
    def task
      @task ||= Task.new
    end

    # +cmdline+ is an instance of +Cmdline::Parser+ that represents the arguments
    # that were passed via the commandline. It handles parsing those arguments,
    # and choosing the task to perform based on the 'verb' supplied - e.g. 'meet',
    # 'list', etc.
    def cmdline
      @cmdline ||= Cmdline::Parser.for(ARGV)
    end

    def host
      Babushka::LogHelpers.removed! :method_name => 'Babushka::Base.host', :instead => "Babushka.host"
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
      @sources ||= SourcePool.new(task.opts.slice(:update))
    end

    def threads
      @threads ||= []
    end

    def in_thread &block
      threads.push Thread.new(&block)
    end

    # The top-level entry point for babushka runs invoked at the command line.
    # When the `babushka` command is run, bin/babushka.rb first triggers a load
    # via lib/babushka.rb, and then calls this method.
    def run
      cmdline.run
    ensure
      threads.each(&:join)
    end

    def exit_on_interrupt!
      if $stdin.tty?
        stty_save = `stty -g`.chomp
        trap("INT") {
          system "stty", stty_save
          unless Base.task.callstack.empty?
            puts "\n#{Logging.closing_log_message("#{Base.task.callstack.first.contextual_name} (cancelled)", false, :closing_status => true)}"
          end
          exit false
        }
      end
    end

    def runtime_info
      @runtime_info ||= "babushka@#{ref} | #{ShellHelpers.which('ruby')}@#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
    end

    def ref
      @ref ||= begin
        repo = GitRepo.new(Path.path)
        repo.current_head if repo.exists?
      end
    end

    def program_name
      @program_name ||= ENV['PATH'].split(':').include?(File.dirname($0)) ? File.basename($0) : $0
    end
  end
  end
end
