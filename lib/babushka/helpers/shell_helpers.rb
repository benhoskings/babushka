module Babushka
  module ShellHelpers
    # Run +cmd+.
    #
    # If the command succeeds (i.e. returns 0), its output will be returned
    # with a trailing newline stripped, if there was one. If the command fails
    # (i.e. returns a non-zero value), nil will be returned.
    #
    # If a block is given, it will be yielded once the command has run, with a
    # Babushka::Shell object as its sole argument. Details of the shell command
    # are contained in this object - see the methods +cmd+, +result+, +stdout+
    # and +stderr+.
    #
    # Several options can be provided to alter #shell's behaviour.
    #   <tt>:sudo => true</tt> runs the the command as root. If the command
    #     contains piping or redirection, a 'sudo su' variant will be used
    #     instead so that the pipe receiver or redirect targets are also
    #     included in the sudo.
    #   <tt>:as => 'user'</tt> causes sudo to run as the specified user instead
    #     of root.
    #   <tt>:sudo => 'user'</tt> is a shortcut that has the same effect as
    #     <tt>:sudo => true, :as => 'user'</tt>
    #   <tt>:cd</tt> specifies the directory in which the command should run.
    #     If the path doesn't exist or isn't a directory, an error is raised
    #     unless the <tt>:create</tt> option is also set.
    #     To achieve the directory change, the command is internally updated
    #     to something like `cd #{dir} && #{cmd}`.
    #   <tt>:create</tt> causes the directory specified by the <tt>:cd</tt>
    #     option to be created if it doesn't already exist.
    #   <tt>:input</tt> can be used to supply input for the shell command. It
    #     be any object that can be written to an IO with <tt>io << obj</tt>.
    #     If it is passed, it will be written to the command's stdin pipe
    #     before any output is read.
    #   <tt>:spinner => true</tt> When this option is passed, a /-\| spinner
    #     is printed to stdout, and advanced whenever a line is read on the
    #     command's stdout or stderr pipes. This is useful for monitoring the
    #     progress of a long-running command, like a build or an installer.
    def shell cmd, opts = {}, &block
      if opts[:dir] # deprecated
        log_error "#{caller.first}: #shell's :dir option has been renamed to :cd."
        opts[:cd] = opts[:dir]
      end
      if opts[:cd]
        if !opts[:cd].p.exists?
          if opts[:create]
            opts[:cd].p.mkdir
          else
            raise Errno::ENOENT, opts[:cd]
          end
        end
        cmd = "cd \"#{opts[:cd].p.to_s.gsub('"', '\"')}\" && #{cmd}"
      end
      shell_method = (opts[:as] || opts[:sudo]) ? :sudo : :shell_cmd
      send shell_method, cmd, opts, &block
    end

    # This method is a shortcut for accessing the results of a shell command
    # without using a block. The method itself returns the shell object that
    # is yielded to the block by +#shell+.
    # As an example, this shell command:
    #   shell('grep rails Gemfile') {|shell| shell.stdout }.empty?
    # can be simplified to this:
    #   failable_shell('grep rails Gemfile').stdout.empty?
    def failable_shell cmd, opts = {}
      shell(cmd, opts) {|s| s }
    end

    # Run +cmd+ in a separate interactive shell. This is useful for running
    # commands that depend on something shell-related that was changed during
    # this run, like changing the user's shell. It's also useful for running
    # commands that are only valid on an interactive shell, like rvm-related
    # commands.
    # TODO: specs.
    def login_shell cmd, opts = {}, &block
      if shell('echo $SHELL').p.basename == 'zsh'
        shell %Q{zsh -i -c "#{cmd.gsub('"', '\"')}"}, opts, &block
      else
        shell %Q{bash -l -c "#{cmd.gsub('"', '\"')}"}, opts, &block
      end
    end

    # Run +cmd+ via sudo.
    #
    # The return behaviour and block handling of +#sudo+ are identical to that
    # of +#shell+. In fact, +#sudo+ constructs a sudo command, and then uses
    # +#shell+ internally to run the command.
    #
    # All the options that can be passed to +#shell+ are valid for +#sudo+ as
    # well. The :sudo and :as options can be ommitted, though, which will cause
    # the command to be run as root. Hence, this sudo call:
    #   sudo('ls')
    # is equivalent to these two shell calls:
    #   shell('ls', :sudo => true)
    #   shell('ls', :as => 'root')
    #
    # In the same manner, this sudo call:
    #   sudo('ls', :as => 'ben')
    # is equivalent to these two shell calls:
    #   shell('ls', :sudo => 'ben')
    #   shell('ls', :as => 'ben')
    def sudo cmd, opts = {}, &block
      cmd = cmd.to_s
      opts[:as] ||= opts[:sudo] if opts[:sudo].is_a?(String)
      sudo_cmd = if opts[:su] || cmd[' |'] || cmd[' >']
        "sudo su - #{opts[:as] || 'root'} -c \"#{cmd.gsub('"', '\"')}\""
      else
        "sudo -u #{opts[:as] || 'root'} #{cmd}"
      end
      shell sudo_cmd, opts.discard(:as, :sudo), &block
    end

    # This method returns the full path to the specified command in the PATH,
    # if that command appears anywhere in the PATH. If it doesn't, nil is
    # returned.
    #
    # For example, on a stock OS X machine:
    #   which('ruby')     #=> "/usr/bin/ruby"
    #   which('babushka') #=> nil
    #
    # This is roughly equivalent to using `which` or `type` on the shell.
    # However, because those commands' behaviour and ouptut vary across
    # platforms and shells, we instead use the logic in #cmd_dir.
    def which cmd_name
      matching_dir = cmd_dir(cmd_name)
      matching_dir / cmd_name unless matching_dir.nil?
    end

    # Return the directory from which the specified command would run if
    # invoked via the PATH. If the command doesn't appear in the PATH, nil is
    # returned.
    #
    # For example, on a stock OS X machine:
    #   cmd_dir('ruby')     #=> "/usr/bin"
    #   cmd_dir('babushka') #=> nil
    #
    # This is a direct implementation because the behaviour and output of
    # `which` and `type` vary across different platforms and shells. It's
    # also faster to not shell out.
    def cmd_dir cmd_name
      ENV['PATH'].split(':').detect {|path|
        (path / cmd_name).executable?
      }
    end

    # Run a shell command, logging before and after using #log_block, and using
    # a spinner while the command runs.
    # The first argument, +message+, is the message to print before running the
    # command, and the remaining arguments are identical to those of #shell.
    #
    # As an example, suppose we called #log_shell as follows:
    #   log_shell('Sleeping for a bit', 'sleep 10')
    #
    # While the command runs, the log would show
    #   Sleeping for a bit... (without a newline)
    #
    # The command runs with a /-\| spinner that animates each time a line of
    # output is emitted by the command. Once the command terminates, the log
    # would be completed to show
    #   Sleeping for a bit... done.
    def log_shell message, cmd, opts = {}, &block
      log_block message do
        shell cmd, opts.merge(:spinner => true), &block
      end
    end

    private

    def shell_cmd cmd, opts = {}, &block
      Shell.new(cmd, opts).run(&block)
    end
  end
end
