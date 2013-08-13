module Babushka
  class SSH

    attr_reader :host

    def initialize host
      @host = host
    end

    def shell *cmd
      ShellHelpers.shell "ssh", "-A", host, cmd.map{|i| "'#{i}'" }.join(' '), :log => true
    end

  end
end
