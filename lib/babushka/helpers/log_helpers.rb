# coding: utf-8

module Babushka
  module LogHelpers

    # Make these helpers callable directly on LogHelpers,
    # and private when included.
    module_function

    # Log +message+ to STDERR. This is a shortcut for
    #   log(message, :as => :error)
    def log_stderr message, opts = {}, &block
      log message, opts.merge(:as => :stderr), &block
    end

    # Log +message+ as an error. This is a shortcut for
    #   log(message, :as => :error)
    def log_error message, opts = {}, &block
      log message, opts.merge(:as => :error), &block
    end

    # Log +message+ as a warning. This is a shortcut for
    #   log(message, :as => :warning)
    def log_warn message, opts = {}, &block
      log message, opts.merge(:as => :warning), &block
    end

    # Yield the block, writing a note to the log about it beforehand and
    # afterwards.
    #
    # As an example, suppose we called #log_block as follows:
    #   log_block('Sleeping for a bit') { sleep 10 }
    #
    # While the block yields, the log would show
    #   Sleeping for a bit... (without a newline)
    #
    # Once the block returns, the log would be completed to show
    #   Sleeping for a bit... done.
    def log_block message, opts = {}, &block
      log "#{message}...", :newline => false
      block.call.tap {|result|
        log result ? " #{opts[:success] || 'done'}." : " #{opts[:failure] || 'failed'}", :as => (result ? nil : :error), :indentation => false
      }
    end

    # Write +message+ to the debug log, prefixed with +TickChar+, returning +true+.
    #
    # This is used to report events that have succeeded, or items that are
    # already working. For example, when the package manager reports that a
    # package is already installed, that's an 'OK' that babushka can move on to
    # the next job, and so +log_ok+ is used to report that fact.
    def log_ok message, opts = {}, &block
      log message.end_with('.'), opts.merge(:as => :ok), &block
      true
    end

    # Write +message+ to the debug log.
    #
    # The message will be written to the log in the normal style, but will only
    # appear on STDOUT if debug logging is enabled.
    def debug message, opts = {}, &block
      log message, opts.merge(:debug => !opts[:log]), &block
    end

    def deprecated! date, opts = {}
      callpoint = "#{caller[opts[:skip] || 1].sub(/\:in `.*$/, '')}: " unless opts[:callpoint] == false
      opts[:method_name] ||= "##{caller[0].scan(/`(\w+)'$/).flatten.first}"
      warning = "#{callpoint}#{opts[:method_name]} has been deprecated and will be removed on #{date}."
      instead = " Use #{opts[:instead]} instead#{opts[:example] ? ", e.g.:" : '.'}" unless opts[:instead].nil?
      log_warn "#{warning}#{instead}"
      log opts[:example].strip unless opts[:example].nil?
      log ''
    end

    # Write +message+ to the log.
    #
    # By default, the log is written to STDOUT, and to ~/.babushka/logs/<dep_name>.
    # The log in ~/.babushka/logs is always a full debugging log, but STDOUT
    # only includes debug logging if +--debug+ was supplied on the command
    # line.
    #
    # By default, the message is ended with a newline. You can pass
    # :newline => false to prevent the newline character being added.
    #
    # To specify the message type, you can use :as. There are four custom
    # types supported:
    #   :ok      The message is printed in grey with +TickChar+ prepended, as
    #            used by +log_ok+.
    #   :warning The message is printed in yellow, as used by +log_warn+.
    #   :error   The message is printed in red, as used by +log_error+.
    #   :stderr  The message (representing STDERR output) is printed in bold,
    #            as used by +Shell+ for debug logging.
    #
    # If a block is given, the block is yielded with the indentation level
    # incremented. Opening and closing braces are printed to the log to represent
    # the nesting. (This is the logging style used to show the nesting during dep
    # runs - so please consider other logging styles before using this one, so as
    # not to visually confuse dep runs with other operations.)
    def log message, opts = {}, &block
      # now = Time.now
      # print "#{now.to_i}.#{now.usec}: ".ljust(20) unless opts[:debug]
      printable = !opts[:debug] || Base.task.opt(:debug)
      Logging.print_log(Logging.indentation, printable, false) unless opts[:indentation] == false
      if block_given?
        Logging.print_log("#{message} {".colorize('grey') + "\n", printable, false)
        Logging.indent! if printable
        yield.tap {|result|
          Logging.undent! if printable
          log Logging.closing_log_message(message, result, opts), opts
        }
      else
        message = message.to_s.rstrip.gsub "\n", "\n#{Logging.indentation}"
        message = "#{Logging::TickChar.colorize('grey')} #{message}" if opts[:as] == :ok
        message = message.colorize 'red' if opts[:as] == :error
        message = message.colorize 'yellow' if opts[:as] == :warning
        message = message.colorize 'bold' if opts[:as] == :stderr
        message = message.end_with "\n" unless opts[:newline] == false
        Logging.print_log(message, printable, opts[:as])
        $stdout.flush
        nil
      end
    end
  end

  class Logging
    extend LogHelpers

    TickChar = '✓'
    CrossChar = '✗'

    def self.closing_log_message message, result = true, opts = {}
      message = opts[:closing_status] if opts[:closing_status].is_a?(String)

      if opts[:closing_status] == :status_only
        '}'.colorize('grey') + ' ' + "#{result ? TickChar : CrossChar}".colorize(result ? 'green' : 'red')
      elsif opts[:closing_status] == :dry_run
        '}'.colorize('grey') + ' ' + "#{result ? TickChar : '~'} #{message}".colorize(result ? 'green' : 'blue')
      elsif opts[:closing_status]
        '}'.colorize('grey') + ' ' + "#{result ? TickChar : CrossChar} #{message}".colorize(result ? 'green' : 'red')
      else
        "}".colorize('grey')
      end
    end

    def self.log_exception exception
      log_error "#{exception.backtrace.first}: #{exception.message}"
      debug exception.backtrace * "\n"
    end

    def self.log_table headings, rows
      all_rows = rows.map {|row|
        row.map(&:to_s)
      }.unshift(
        headings
      ).transpose.map {|col|
        max_length = col.map(&:length).max
        col.map {|cell| cell.ljust(max_length) }
      }.transpose

      [
        all_rows.first.join(' | '),
        all_rows.first.map {|i| '-' * i.length }.join('-+-')
      ].concat(
        all_rows[1..-1].map {|row| row.join(' | ') }
      ).each {|row|
        log row
      }
    end


    private

    def self.print_log message, printable, as
      if !printable
        # Only written to the log file.
      elsif [:error, :stderr].include?(as)
        $stderr.print message
      else
        $stdout.print message
      end
      write_to_persistent_log message
    end

    def self.write_to_persistent_log message
      Base.task.persistent_log.write message unless Base.task.persistent_log.nil?
    end

    def self.indentation
      ' ' * indentation_level * 2
    end

    def self.indentation_level
      @indentation_level ||= 0
    end

    def self.indent!
      @indentation_level ||= 0
      @indentation_level += 1
    end

    def self.undent!
      @indentation_level ||= 0
      @indentation_level -= 1
    end
  end
end
