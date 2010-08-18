module Babushka
  module Open3
    def popen3 cmd, &block
      pipes = { :in => IO::pipe, :out => IO::pipe, :err => IO::pipe }
      near = { :in => pipes[:in][1], :out => pipes[:out][0], :err => pipes[:err][0] }
      far = { :in => pipes[:in][0], :out => pipes[:out][1], :err => pipes[:err][1] }

      pid = fork {
        reopen_pipe_for :read, pipes[:in], STDIN
        reopen_pipe_for :write, pipes[:out], STDOUT
        reopen_pipe_for :write, pipes[:err], STDERR
        exec *cmd
      }

      far.values.each &:close
      near.values.each {|p| p.sync = true }

      begin
        yield near[:in], near[:out], near[:err]
        Process.waitpid2(pid).last.exitstatus
      ensure
        near.values.each {|p| p.close unless p.closed? }
      end
    end

    private

    def reopen_pipe_for task, pipe, io
      to_close = pipe[task == :read ? 1 : 0]
      to_reopen = pipe[task == :read ? 0 : 1]
      to_close.close
      io.reopen to_reopen
      to_reopen.close
    end

    module_function :popen3, :reopen_pipe_for
  end
end
