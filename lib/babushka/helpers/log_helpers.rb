# -*- coding: utf-8 -*-

module Babushka
  module LogHelpers
    TickChar = '✓'
    CrossChar = '✗'
    @@indentation_level = 0

    # Log +message+ as an error. This is a shortcut for
    #   log(message, :as => :error)
    def log_error message, opts = {}, &block
      log message, opts.merge(:as => :error), &block
    end

    def log_verbose message, opts = {}, &block
      log message, opts, &block
    end

    def log_result message, opts = {}, &block
      if opts.delete :as_bypass
        log_result message, opts.merge(:fail_symbol => '~', :fail_color => 'blue')
      else
        log [
          (opts[:result] ? TickChar : (opts[:fail_symbol] || '×')).colorize(opts[:result] ? (opts[:ok_color] || 'grey') : (opts[:fail_color] || 'red')),
          "#{message}".colorize(opts[:result] ? (opts[:ok_color] || 'none') : (opts[:fail_color] || 'red'))
        ].join(' ')
      end
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
        log result ? ' done.' : ' failed', :as => (result ? nil : :error), :indentation => false
      }
    end

    # Write +message+ to the debug log, prefixed with +TickChar+.
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
    # To specify the message type, you can use :as. There are three custom
    # types supported:
    #   :ok     The message is printed in grey with +TickChar+ prepended, as
    #           used by +log_ok+.
    #   :error  The message is printed in red, as used by +log_error+.
    #   :stderr The message (representing STDERR output) is printed in blue,
    #           as used within the +Shell+ class for debug logging.
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
      print_log indentation, printable unless opts[:indentation] == false
      if block_given?
        print_log "#{message} {\n".colorize('grey'), printable
        @@indentation_level += 1 if printable
        yield.tap {|result|
          @@indentation_level -= 1 if printable
          log closing_log_message(message, result, opts), opts
        }
      else
        message = message.to_s.rstrip.gsub "\n", "\n#{indentation}"
        message = "#{TickChar.colorize('grey')} #{message}" if opts[:as] == :ok
        message = message.colorize 'red' if opts[:as] == :error
        message = message.colorize 'bold' if opts[:as] == :stderr
        message = message.end_with "\n" unless opts[:newline] == false
        print_log message, printable
        $stdout.flush
        nil
      end
    end

    def closing_log_message message, result = true, opts = {}
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

    def log_table headings, rows
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

    def print_log message, printable
      print message if printable
      write_to_persistent_log message
    end

    def write_to_persistent_log message
      Base.task.persistent_log.write message unless Base.task.persistent_log.nil?
    end

    def indentation
      ' ' * @@indentation_level * 2
    end
  end
end
