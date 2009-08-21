module Babushka
  class Task

    attr_reader :base_opts, :run_opts, :vars

    def initialize
      @vars = Hash.new {|hsh,k| hsh[k] = {} }
      @base_opts = default_base_opts
      @run_opts = default_run_opts
    end

    def opts
      @base_opts.merge @run_opts
    end

    def debug?
      opts[:debug]
    end
    def quiet?
      opts[:quiet]
    end
    def dry_run?
      opts[:dry_run]
    end
    def callstack
      opts[:callstack]
    end


    private

    def default_base_opts
      {}
    end


    def default_run_opts
      {
        :callstack => []
      }
    end

  end
end
