# coding: utf-8

require 'shellwords'

module Babushka
  # Represents an ssh connection to a remote host.
  #
  # This class prioritises simplicity over performance; there's no connection
  # re-use, or any state apart from the address of the host. Every connection
  # is new and independent of any others.
  class SSH

    attr_reader :host

    def initialize host
      @host = host
    end

    # Run cmd on the remote host via ssh. Arguments will be escaped for the
    # shell as required.
    def shell *cmd
      # We would do this, but ruby 1.8 can't handle options after a splat:
      #   ShellHelpers.shell("ssh", "-A", host, *cmd, :log => true)
      args = ["ssh", "-A", host].concat(cmd).push(:log => true)
      ShellHelpers.shell(*args)
    end

    # Log the command to be run on the remote host, including argument details,
    # and then run it using #shell within an indented log block. The result of
    # the command will be logged at the end of the indented section.
    def log_shell *cmd
      cmd_message = [
        host.colorize("on grey"),
        cmd.map {|i| i.sub(/^(.{40})(.).+/m, '\1…') }.join(' ') # Truncate long args
      ].join(' $ ')

      LogHelpers.log cmd_message, :closing_status => cmd_message do
        shell(*cmd)
      end
    end

    # Run babushka on the remote host with the given dep specification and
    # arguments, logging the remote command and its output.
    #
    # Functionally, this is identical to running babushka manually on the
    # remote commandline, except that the remote stdin is not a terminal.
    def babushka dep_spec, args = {}
      remote_args = [
        '--defaults',
        '--git-fs',
        '--show-args',
        ('--colour' if $stdin.tty?),
        ('--update' if Babushka::Base.task.opt(:update)),
        ('--debug'  if Babushka::Base.task.opt(:debug))
      ].compact

      dep_args = args.keys.map {|k| "#{k}=#{Shellwords.escape(args[k].to_s)}" }.sort

      remote_args.concat(dep_args)

      log_shell('babushka', Shellwords.escape(dep_spec), *remote_args).tap {|result|
        raise Babushka::UnmeetableDep, "The remote babushka reported an error." unless result
      }
    end

  end
end
