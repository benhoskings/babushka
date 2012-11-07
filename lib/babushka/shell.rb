module Babushka
  class Shell
    include LogHelpers

    class ShellCommandFailed < StandardError
      attr_reader :cmd, :stdout, :stderr
      def initialize cmd, stdout, stderr
        @cmd, @stdout, @stderr = cmd, stdout, stderr
        message = if stderr.empty?
          "Shell command failed: '#{cmd.join(' ')}'"
        else
          "Shell command failed: '#{cmd.join(' ')}':\n#{stderr}"
        end
        super message
      end
    end

    attr_reader :cmd, :opts, :env, :result, :stdout, :stderr

    def initialize *cmd
      @opts = cmd.extract_options!
      raise ArgumentError, "You can't use :spinner and :progress together in Babushka::Shell." if opts[:spinner] && opts[:progress]
      raise ArgumentError, "wrong number of arguments (0 for 1+)" if cmd.empty?
      @env = cmd.first.is_a?(Hash) ? cmd.shift : {}
      @cmd = cmd
      @progress = nil
    end

    def ok?
      result == 0
    end

    def run &block
      @stdout, @stderr = '', ''
      @result = invoke
      print "#{" " * (@progress.length + 1)}#{"\b" * (@progress.length + 1)}" unless @progress.nil?

      if block_given?
        yield(self)
      elsif ok?
        stdout.chomp
      else
        raise ShellCommandFailed.new(cmd, stdout, stderr)
      end
    end

    private

    def invoke
      debug "$ #{@cmd.join(' ')}".colorize('grey')
      Babushka::Open3.popen3 @cmd, popen_opts do |stdin,stdout,stderr,thread|
        unless opts[:input].nil?
          stdin << opts[:input]
        end
        stdin.close

        spinner_offset = -1
        should_spin = opts[:spinner] && !Base.task.opt(:debug)

        fds = []
        fds << stderr unless stderr.closed?
        fds << stdout unless stdout.closed?

        loop {
          rs,_,_  = IO.select(fds, [], [])
          rs.each do |fd|
            case fd
            when stdout
              read_from stdout, @stdout do
                print " #{%w[| / - \\][spinner_offset = ((spinner_offset + 1) % 4)]}\b\b" if should_spin
              end
            when stderr
              read_from stderr, @stderr, :stderr
            end
          end

          fds.delete(stdout) if stdout.closed?
          fds.delete(stderr) if stderr.closed?

          break if fds.empty?
        }
      end
    end

    def read_from io, buf, log_as = nil
      while !io.closed? && io.ready_for_read?
        output = nil
        # Try reading less than a full line (up to just a backspace) if we're
        # looking for progress output.
        output = io.gets("\r") if opts[:progress]
        output = io.gets if output.nil?

        if output.nil?
          io.close
        else
          debug output.chomp, :log => opts[:log], :as => log_as
          buf << output
          if opts[:progress] && (@progress = output[opts[:progress]])
            print " #{@progress}#{"\b" * (@progress.length + 1)}"
          end
          yield if block_given?
        end
      end
    end

    def popen_opts
      {}.tap {|opts_to_pass|
        opts_to_pass[:chdir] = opts[:cd].p.to_s if opts[:cd]
        opts_to_pass[:env] = env if env
      }
    end
  end
end
