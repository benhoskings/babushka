module Babushka
  class Open3
    def self.popen3 cmd, opts = {}, &block
      pipe_in, pipe_out, pipe_err = IO::pipe, IO::pipe, IO::pipe

      # To write to the process' STDIN, and read from its STDOUT/ERR.
      near = [pipe_in[1], pipe_out[0], pipe_err[0]]
      # The other ends, connected to the process.
      far  = [pipe_in[0], pipe_out[1], pipe_err[1]]

      pid = fork {
        reopen_pipe_for :read, pipe_in, STDIN
        reopen_pipe_for :write, pipe_out, STDOUT
        reopen_pipe_for :write, pipe_err, STDERR

        ENV.update opts[:env] if opts[:env]

        PathHelpers.cd(opts[:chdir]) {
          exec(*cmd)
        }
      }

      near.each {|p| p.sync = true }
      far.each(&:close)

      begin
        yield(*near)
        Process.waitpid2(pid).last.exitstatus
      ensure
        near.each {|p| p.close unless p.closed? }
      end
    end

  private

    def self.reopen_pipe_for task, pipe, io
      to_close = pipe[task == :read ? 1 : 0]
      to_reopen = pipe[task == :read ? 0 : 1]
      to_close.close
      io.reopen to_reopen
      to_reopen.close
    end
  end
end
