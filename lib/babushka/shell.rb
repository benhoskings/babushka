module Babushka
  class Shell
    attr_reader :cmd, :result, :stdout, :stderr
    class ShellResult
      attr_reader :shell

      def initialize shell, opts, &block
        @shell, @opts, @block = shell, opts, block
      end

      def render
        if @block.nil?
          shell.stdout.chomp if shell.ok?
        else
          @block.call shell
        end
      end
    end

    def initialize first, *rest
      @cmd = first.is_a?(Array) ? first : [first].concat(rest)
    end

    def ok?; result end

    def run opts = {}, &block
      debug "$ #{[*@cmd].join(' ')}".colorize('grey')
      @stdout, @stderr = '', ''

      popen3_result = Babushka::Open3.popen3 @cmd do |stdin,stdout,stderr|
        unless opts[:input].nil?
          stdin << opts[:input]
          stdin.close
        end

        stdout_done = stderr_done = false

        spinner_offset = -1
        should_spin = opts[:spinner] && !Base.task.opt(:debug)
        spinner_updated_at = Time.now - 1

        until stdout_done && stderr_done
          stdout_ready = stdout.ready_for_read?
          stderr_ready = stderr.ready_for_read?

          if !stdout_ready && !stderr_ready
            sleep 0.01 #if stdout_done || stderr_done
          else
            if should_spin && (Time.now - spinner_updated_at > 0.05)
              print '  ' if spinner_offset == -1
              print "\b\b #{%w[| / - \\][spinner_offset = ((spinner_offset + 1) % 4)]}"
              spinner_updated_at = Time.now
            end
            if stdout_ready
              if (buf = stdout.gets).nil?
                stdout_done = true
              else
                debug buf.chomp, :log => opts[:log]
                @stdout << buf
              end
            end
            if stderr_ready
              if (buf = stderr.gets).nil?
                stderr_done = true
              else
                debug buf.chomp, :log => opts[:log], :as => :stderr
                @stderr << buf
              end
            end
          end
        end
        print "\b\b" if should_spin unless spinner_offset == -1
      end

      @result = popen3_result == 0
      ShellResult.new(self, opts, &block).render
    end
  end
end
