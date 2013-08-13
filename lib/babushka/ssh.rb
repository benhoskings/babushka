module Babushka
  class SSH

    attr_reader :host

    def initialize host
      @host = host
    end

    def shell *cmd
      ShellHelpers.shell "ssh", "-A", host, cmd.map{|i| "'#{i}'" }.join(' '), :log => true
    end

    def babushka dep_spec
      shell('babushka', dep_spec).tap {|result|
        raise Babushka::UnmeetableDep, "The remote babushka reported an error." unless result
      }
    end

  end
end
