module Babushka
  module DepRunnerHelpers
    def self.included base # :nodoc:
      base.send :include, HelperMethods
    end

    module HelperMethods
    end
  end

  class DepRunner
    include ShellHelpers
    include PromptHelpers
    include DefinerHelpers

    attr_reader :dep, :vars, :opts

    delegate :name, :to => :dep

    def initialize dep
      @dep = dep
      @vars = Hash.new {|hsh,k| hsh[k] = {} }
      @opts = default_opts
    end

    def definer
      @dep.definer
    end

    def attempt_to_meet
      opts[:attempt_to_meet]
    end
    def callstack
      opts[:callstack]
    end

    def set key, value
      define_var_accessors key unless respond_to? key
      send "#{key}=", value
    end
    def merge key, value
      set key, ((vars[key.to_s] || {})[:value] || {}).merge(value)
    end

    def var name
      define_var name.to_s unless vars.has_key? name.to_s
      if vars[name.to_s].has_key? :value
        vars[name.to_s][:value]
      else
        ask_for_var name.to_s
      end
    end

    def define_var_accessors key
      self.class.instance_eval {
        define_method key do
          vars[key.to_s][:value]
        end
        define_method "#{key}=" do |value|
          vars[key.to_s][:value] = value
        end
      }
    end

    def define_var name, opts = {}
      vars[name.to_s] = opts.dragnet(:default, :type)
    end

    def ask_for_var key
      printable_key = key.to_s.gsub '_', ' '
      set key, send("read_#{vars[key][:type] || 'value'}_from_prompt",
        "#{printable_key}#{" for #{name}" unless printable_key == name}",
        :default => vars[key][:default]
      )
    end


    private

    def default_opts
      {
        :callstack => []
      }
    end

  end
end
