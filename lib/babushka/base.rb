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
    Options = {
      :quiet => %w[-q --quiet],
      :debug => '--debug',
      :dry_run => %w[-n --dry-run],
      :force => %w[-f --force]
    }.freeze

    def opts
      @opts || {}
    end

    def run args
      if !(@setup ||= setup(args))
        # fail
      elsif @tasks.empty?
        fail_with "Nothing to do."
      else
        @tasks.all? {|dep_name|
          dep = Dep(dep_name)
          dep.meet(:vars => @vars) unless dep.nil?
        }
      end
    end


    private

    def setup args
      extract_opts(args).tap{|obj| debug "opts=#{obj.inspect}" }
      extract_vars(args).tap{|obj| debug "vars=#{obj.inspect}" }
      extract_tasks(args).tap{|obj| debug "tasks=#{obj.inspect}" }
      load_deps
    end

    def extract_opts args
      @opts = Options.inject({}) {|opts,(opt_name,opt)|
        opts[opt_name] = !args.extract! {|arg| arg == opt }.empty?
        opts
      }
    end

    def extract_vars args
      @vars = args.extract! {|arg| arg['='] }.inject({}) {|vars,arg|
        key, value = arg.split('=', 2)
        vars[key] = value
        vars
      }
    end

    def extract_tasks args
      @tasks = args
    end

    def load_deps
      %w[~/.babushka/deps ./deps].all? {|dep_path| DepDefiner.load_deps_from dep_path }
    end

    def fail_with message
      log message
      exit 1
    end
  end
  end
end
