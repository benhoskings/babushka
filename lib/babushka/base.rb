module Babushka
  Version = '0.0.1'

  module BaseHelpers
    def self.included base # :nodoc:
      Object.send :include, HelperMethods
    end

    module HelperMethods
      def Babushka argv
        Babushka::Base.run argv
      end
    end
  end


  class Base
  class << self
    attr_reader :opts

    def run args
      if !(@setup ||= setup(args))
        log "There was a problem loading deps."
      elsif @tasks.empty?
        log "Nothing to do."
      else
        @tasks.all? {|dep_name|
          dep = Dep(dep_name)
          dep.meet unless dep.nil?
        }
      end
    end


    private

    def setup args
      @tasks, @opts = parse_args args
      %w[~/.babushka/deps ./deps].all? {|dep_path| DepDefiner.load_deps_from dep_path }
    end

    def parse_args args
      parse_opts args.dup, {
        :quiet => %w[-q --quiet],
        :debug => '--debug',
        :dry_run => %w[-n --dry-run],
        :force => %w[-f --force]
      }
    end

    def parse_opts args, opts
      opts.keys.each {|k|
        opts[k] = ![*opts[k]].map {|arg| args.delete arg }.first.blank?
      }
      [args, opts]
    end
  end
  end
end
