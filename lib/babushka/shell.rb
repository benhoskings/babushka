module Babushka
  module ShellHelpers
    def self.included base # :nodoc:
      base.send :include, HelperMethods
    end

    module HelperMethods
      def shell_cmd cmd, opts = {}, &block
        Shell.new(cmd).run opts, &block
      end
    end
  end

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

    def initialize cmd
      @cmd = cmd
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

        until stdout_done && stderr_done
          stdout_ready = stdout.ready_for_read?
          stderr_ready = stderr.ready_for_read?

          if !stdout_ready && !stderr_ready
            sleep 0.01 #if stdout_done || stderr_done
          else
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
      end.zero?

      ShellResult.new(self, opts, &block).render
    end
  end
end
