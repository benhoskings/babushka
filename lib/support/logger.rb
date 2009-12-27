# -*- coding: utf-8 -*-

module Babushka
  class Logger
    module Helpers
      TickChar = '√'
      CrossChar = '×'
      @@indentation_level = 0

      def log_error message, opts = {}, &block
        log message, opts.merge(:as => :error), &block
      end

      def log_verbose message, opts = {}, &block
        if !opts[:quiet]
          log message, opts, &block
        elsif block_given?
          yield
        end
      end

      def log_extra message, opts = {}, &block
        log_verbose message.colorize('grey'), opts, &block
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

      def log_ok message, opts = {}, &block
        if !Base.task.opt(:quiet)
          log message.end_with('.'), opts.merge(:as => :ok), &block
          true
        elsif block_given?
          yield
        end
      end

      def debug message, opts = {}, &block
        log message, opts.merge(:debug => !opts[:log]), &block
      end

      def log message, opts = {}, &block
        # now = Time.now
        # print "#{now.to_i}.#{now.usec}: ".ljust(20) unless opts[:debug]
        printable = !opts[:debug] || Base.task.opt(:debug)
        print_log indentation, printable unless opts[:indentation] == false
        if block_given?
          print_log "#{message} {\n".colorize('grey'), printable
          @@indentation_level += 1 if printable
          returning yield do |result|
            @@indentation_level -= 1 if printable
            if opts[:closing_status] == :status_only
              log '}'.colorize('grey') + ' ' + "#{result ? TickChar : CrossChar}".colorize(result ? 'green' : 'red'), opts
            elsif opts[:closing_status] == :dry_run
              log '}'.colorize('grey') + ' ' + "#{result ? TickChar : '~'} #{message}".colorize(result ? 'green' : 'blue'), opts
            elsif opts[:closing_status]
              log '}'.colorize('grey') + ' ' + "#{result ? TickChar : CrossChar} #{message}".colorize(result ? 'green' : 'red'), opts
            else
              log "}".colorize('grey'), opts
            end
          end
        else
          message = message.to_s.rstrip.gsub "\n", "\n#{indentation}"
          message = "#{TickChar.colorize('grey')} #{message}" if opts[:as] == :ok
          message = message.colorize 'red' if opts[:as] == :error
          message = message.colorize 'blue' if opts[:as] == :stderr
          message = message.end_with "\n" unless opts[:newline] == false
          print_log message, printable
          $stdout.flush
          nil
        end
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
end
