module Babushka
  class Shell
    include LogHelpers

    attr_reader :cmd, :opts, :env, :result, :stdout, :stderr

    def initialize *cmd
      @opts = cmd.extract_options!
      raise "You can't use :spinner and :progress together in Babushka::Shell." if opts[:spinner] && opts[:progress]
      @env = cmd.first.is_a?(Hash) ? cmd.shift : {}
      @cmd = cmd
      @progress = nil
    end

    def ok?; result == 0 end

    def run &block
      @stdout, @stderr = '', ''
      @result = invoke
      print "#{" " * (@progress.length + 1)}#{"\b" * (@progress.length + 1)}" unless @progress.nil?

      if block_given?
        yield(self)
      elsif ok?
        stdout.chomp
      elsif stderr.empty? && stdout.empty?
        log "$ #{@cmd.join(' ')}".colorize('grey') + ' ' + "#{Logging::CrossChar} shell command failed".colorize('red')
      else
        log "$ #{@cmd.join(' ')}", :closing_status => 'shell command failed' do
          log_error(stderr.empty? ? stdout : stderr)
        end
      end
    end

    private

    def invoke
      debug "$ #{@cmd.join(' ')}".colorize('grey')
      Babushka::Open3.popen3 @cmd, popen_opts do |stdin,stdout,stderr,thread|
        unless @opts[:input].nil?
          stdin << @opts[:input]
          stdin.close
        end

        spinner_offset = -1
        should_spin = @opts[:spinner] && !Base.task.opt(:debug)

        # For very short-running commands, check for output in a tight loop.
        # The sleep below would at least halve the speed of quick #shell calls.
        # This means really quick calls (e.g. `whoami`, `pwd`, etc) aren't
        # delayed, but the CPU is only pegged for a fraction of a second on
        # slower calls (e.g. `gem env`, `make`, etc).
        1_000.times { break if stdout.ready_for_read? || stderr.ready_for_read? }

        loop {
          read_from stdout, @stdout do
            print " #{%w[| / - \\][spinner_offset = ((spinner_offset + 1) % 4)]}\b\b" if should_spin
          end
          read_from stderr, @stderr, :stderr

          if stdout.closed? && stderr.closed?
            break
          else
            # We sleep here because otherwise babushka itself would peg the CPU
            # while waiting for output from long-running shell commands.
            sleep 0.05
          end
        }
      end
    end

    def read_from io, buf, log_as = nil
      while !io.closed? && io.ready_for_read?
        output = nil
        # Only try reading up to a backspace if we're looking for progress output.
        output = io.gets("\r") if @opts[:progress]
        output = io.gets if output.nil?

        if output.nil?
          io.close
        else
          debug output.chomp, :log => @opts[:log], :as => log_as
          buf << output
          if @opts[:progress] && (@progress = output[@opts[:progress]])
            print " #{@progress}#{"\b" * (@progress.length + 1)}"
          end
          yield if block_given?
        end
      end
    end

    def popen_opts
      {}.tap {|opts|
        opts[:chdir] = @opts[:cd].p.to_s if @opts[:cd]
        opts[:env] = @env if @env
      }
    end
  end
end
