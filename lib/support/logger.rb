module Babushka
  module LoggerHelpers
    def self.included base # :nodoc:
      (Logger.metaclass.instance_methods - Class.instance_methods).each {|method_name|
        base.instance_eval {
          define_method method_name do |*args, &block|
            Logger.send method_name, *args, &block
          end
        }
      }
    end
  end

  class Logger
  class << self
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
      log [
        (opts[:result] ? TickChar : (opts[:fail_symbol] || '×')).colorize(opts[:result] ? (opts[:ok_color] || 'grey') : (opts[:fail_color] || 'red')),
        "#{message}".colorize(opts[:result] ? (opts[:ok_color] || 'none') : (opts[:fail_color] || 'red'))
      ].join(' ')
    end

    def log_ok message, opts = {}, &block
      if !Base.opts[:quiet]
        log message.end_with('.'), opts.merge(:as => :ok), &block
        true
      elsif block_given?
        yield
      end
    end

    def debug message, opts = {}, &block
      if Base.opts[:debug]
        log message, opts, &block
      elsif block_given?
        yield
      end
    end

    def log message, opts = {}, &block
      print indentation unless opts[:indentation] == false
      if block_given?
        print "#{message} {\n".colorize('grey')
        @@indentation_level += 1
        returning yield do |result|
          @@indentation_level -= 1
          if opts[:closing_status] == :dry_run
            log '}'.colorize('grey') + ' ' + "#{result ? TickChar : '~'} #{message}".colorize(result ? 'green' : 'blue')
          elsif opts[:closing_status]
            log '}'.colorize('grey') + ' ' + "#{result ? TickChar : CrossChar} #{message}".colorize(result ? 'green' : 'red')
          else
            log "}".colorize('grey')
          end
        end
      else
        message.gsub! "\n", "\n#{indentation}"
        message = "#{TickChar.colorize('grey')} #{message}" if opts[:as] == :ok
        message = message.colorize 'red' if opts[:as] == :error
        message = message.end_with "\n" unless opts[:newline] == false
        print message
        $stdout.flush
        nil
      end
    end


    private

    def indentation
      ' ' * @@indentation_level * 2
    end
  end
  end
end
