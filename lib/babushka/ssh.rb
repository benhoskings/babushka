require 'shellwords'

module Babushka
  class SSH

    attr_reader :host

    def initialize host
      @host = host
    end

    def shell *cmd
      # We would do this, but ruby 1.8 can't handle options after a splat:
      #   ShellHelpers.shell("ssh", "-A", host, *cmd, :log => true)
      args = ["ssh", "-A", host].concat(cmd).push(:log => true)
      ShellHelpers.shell(*args)
    end

    def babushka dep_spec, args = {}
      remote_args = [
        '--defaults',
        '--git-fs',
        '--show-args',
        ('--colour' if $stdin.tty?),
        ('--update' if Babushka::Base.task.opt(:update)),
        ('--debug'  if Babushka::Base.task.opt(:debug))
      ].compact

      dep_args = args.keys.map {|k| "#{k}=#{Shellwords.escape(args[k])}" }.sort

      remote_args.concat(dep_args)

      shell('babushka', Shellwords.escape(dep_spec), *remote_args).tap {|result|
        raise Babushka::UnmeetableDep, "The remote babushka reported an error." unless result
      }
    end

  end
end
