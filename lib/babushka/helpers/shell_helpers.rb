module Babushka
  module ShellHelpers
    include LogHelpers

    # Run +cmd+.
    #
    # If the command succeeds (i.e. returns 0), its output will be returned
    # with a trailing newline stripped, if there was one. If the command fails
    # (i.e. returns a non-zero value), nil will be returned.
    #
    # If a block is given, it will be yielded once the command has run, with a
    # Babushka::Shell object as its sole argument. Details of the shell command
    # are contained in this object - see the methods +cmd+, +ok?+, +result+,
    # +stdout+, and +stderr+.
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
    #     To achieve the directory change, the command is rewritten to change
    #     directory first: `cd #{dir} && #{cmd}`.
    #   <tt>:create</tt> causes the directory specified by the <tt>:cd</tt>
    #     option to be created if it doesn't already exist.
    #   <tt>:input</tt> can be used to supply input for the shell command. It
    #     be any object that can be written to an IO with <tt>io << obj</tt>.
    #     When passed, it will be written to the command's stdin pipe before
    #     any output is read.
    #   <tt>:spinner => true</tt> When this option is passed, a /-\| spinner
    #     is printed to stdout, and advanced whenever a line is read on the
    #     command's stdout or stderr pipes. This is useful for monitoring the
    #     progress of a long-running command, like a build or an installer.
    def shell *cmd, &block
      shell!(*cmd, &block)
    rescue Shell::ShellCommandFailed => e
      if cmd.extract_options[:log]
        # Don't log the error if the command already logged
      elsif e.stdout.empty? && e.stderr.empty?
        log "$ #{e.cmd.join(' ')}".colorize('grey') + ' ' + "#{Logging::CrossChar} shell command failed".colorize('red')
      else
        log "$ #{e.cmd.join(' ')}", :closing_status => 'shell command failed' do
          log_error(e.stderr.empty? ? e.stdout : e.stderr)
        end
      end
    end

    # Run +cmd+, returning true if its exit code was 0.
    #
    # This is useful to run shell commands whose output isn't important,
    # but whose exit code is. Unlike +#shell+, which logs the output of shell
    # commands that exit with non-zero status, +#shell?+ runs silently.
    #
    # The idea is that +#shell+ is for when you're interested in the command's
    # output, and +#shell?+ is for when you're interested in the exit status.
    def shell? *cmd
      shell(*cmd) {|s| s.stdout.chomp if s.ok? }
    end

    # Run +cmd+ via #shell, raising an exception if it doesn't exit
    # with success.
    def shell! *cmd, &block
      opts = cmd.extract_options!
      cmd = cmd.first if cmd.map(&:class) == [Array]

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
      end
      shell_method = (opts[:as] || opts[:sudo]) ? :sudo : :shell_cmd
      send shell_method, *cmd.dup.push(opts), &block
    end

    # This method is a shortcut for accessing the results of a shell command
    # without using a block. The method itself returns the shell object that
    # is yielded to the block by +#shell+.
    # As an example, this shell command:
    #   shell('grep rails Gemfile') {|shell| shell.stdout }.empty?
    # can be simplified to this:
    #   raw_shell('grep rails Gemfile').stdout.empty?
    def raw_shell *cmd
      shell(*cmd) {|s| s }
    end

    def failable_shell *cmd
      log_error "#failable_shell has been renamed to #raw_shell." # deprecated
      raw_shell(*cmd)
    end

    # Run +cmd+ in a separate interactive shell. This is useful for running
    # commands that depend on something shell-related that was changed during
    # this run, like changing the user's shell. It's also useful for running
    # commands that are only valid on an interactive shell, like rvm-related
    # commands.
    def login_shell cmd, opts = {}, &block
      if shell('echo $SHELL').p.basename == 'zsh'
        shell %Q{zsh -i -c "#{cmd.gsub('"', '\"')}"}, opts, &block
      else
        shell %Q{bash -l -c "#{cmd.gsub('"', '\"')}"}, opts, &block
      end
    end

    # Run +cmd+ via `sudo`, bypassing it if possible (i.e. if we're running as
    # root already, or as the user that was requested).
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
    def sudo *cmd, &block
      opts = cmd.extract_options!
      env = cmd.first.is_a?(Hash) ? cmd.shift : {}

      if cmd.map(&:class) != [String]
        raise ArgumentError, "#sudo commands have to be passed as a single string, not splatted strings or an array, since the `sudo` is composed from strings."
      end

      raw_as = opts[:as] || opts[:sudo] || 'root'
      as = raw_as == true ? 'root' : raw_as
      cmd = cmd.last

      sudo_cmd = if current_username == as
        cmd # Don't sudo if we're already running as the specified user.
      else
        if opts[:su] || cmd[' |'] || cmd[' >']
          "sudo su - #{as} -c \"#{cmd.gsub('"', '\"')}\""
        else
          "sudo -u #{as} #{cmd}"
        end
      end

      shell [env, sudo_cmd], opts.discard(:as, :sudo, :su), &block
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
      File.join(matching_dir, cmd_name.to_s) unless matching_dir.nil?
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
        File.executable? File.join(path, cmd_name.to_s)
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
    def log_shell message, *cmd, &block
      opts = cmd.extract_options!
      log_block message do
        shell *cmd.dup.push(opts.merge(:spinner => true)), &block
      end
    end

    private

    def shell_cmd *cmd, &block
      Shell.new(*cmd).run(&block)
    end

    def current_username
      require 'etc'
      Etc.getpwuid(Process.euid).name
    end
  end
end
