module Babushka
  class Shell
    module Helpers
      def shell_cmd cmd, opts = {}, &block
        Shell.new(cmd).run opts, &block
      end
      def shell cmd, opts = {}, &block
        shell_method = opts.delete(:sudo) ? :sudo : :shell_cmd
        send shell_method, cmd, opts, &block
      end
      def failable_shell cmd, opts = {}
        shell = nil
        Babushka::Shell.new(cmd).run opts.merge(:fail_ok => true) do |s|
          shell = s
        end
        shell
      end
      def sudo cmd, opts = {}, &block
        cmd = cmd.to_s
        sudo_cmd = if opts[:su] || cmd[' |'] || cmd[' >']
          "sudo su - #{opts[:as] || 'root'} -c \"#{cmd.gsub('"', '\"')}\""
        else
          "sudo -u #{opts[:as] || 'root'} #{cmd}"
        end
        shell sudo_cmd, opts, &block
      end
    end

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

    def initialize cmd
      @cmd = cmd.to_s
    end

    def ok?; result end

    def run opts = {}, &block
      debug "$ #{@cmd}".colorize('grey')
      @stdout, @stderr = '', ''

      @result = Babushka::Open3.popen3 @cmd do |stdin,stdout,stderr|
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
      end.zero?

      ShellResult.new(self, opts, &block).render
    end
  end
end
