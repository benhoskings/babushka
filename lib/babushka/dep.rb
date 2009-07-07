module Babushka
  module DepHelpers
    def self.included base # :nodoc:
      base.send :include, HelperMethods
    end

    module HelperMethods
      def Dep name;                    Dep.for name                             end
      def dep name, opts = {}, &block; Dep.new name, opts, block                end
      def pkg name, opts = {}, &block; Dep.new name, opts, block, PkgDepDefiner end
      def gem name, opts = {}, &block; Dep.new name, opts, block, GemDepDefiner end
      def ext name, opts = {}, &block; Dep.new name, opts, block, ExtDepDefiner end
    end
  end

  class Dep
    include PromptHelpers

    attr_reader :name, :local_vars, :opts, :run_opts
    attr_accessor :unmet_message

    def initialize name, in_opts, block, definer_class = DepDefiner
      @name = name
      @local_vars = {}
      @opts = {
        :for => :all
      }.merge in_opts
      @run_opts = default_run_opts
      @definer = definer_class.new self, &block
      @definer.process
      debug "\"#{name}\" depends on #{payload[:requires].inspect}"
      Dep.register self
    end

    def self.deps
      @@deps ||= {}
    end
    def self.count
      deps.length
    end
    def self.names
      @@deps.keys
    end

    def self.register dep
      raise "There is already a registered dep called '#{dep.name}'." unless deps[dep.name].nil?
      deps[dep.name] = dep
    end
    def self.for name
      returning dep = deps[name] do |result|
        log"#{name.colorize 'grey'} #{"<- this dep isn't defined!".colorize('red')}" unless result
      end
    end

    def met? run_opts = {}
      process default_run_opts.merge(run_opts).merge :attempt_to_meet => false
    end
    def meet run_opts = {}
      process default_run_opts.merge(run_opts).merge :attempt_to_meet => !Base.opts[:dry_run]
    end

    def vars
      run_opts[:parent_vars].merge(run_opts[:child_vars]).merge(local_vars)
    end
    def set key, value
      @local_vars[key.to_s] = value
    end

    def ask_for_var key, default = nil
      # TODO this should be elsewhere
      read_method = [payload[:run_in]].include?(key) ? :read_path_from_prompt : :read_value_from_prompt
      printable_key = key.to_s.gsub '_', ' '
      @local_vars[key] = send read_method, "#{printable_key}#{" for #{name}" unless printable_key == name}", :default => default
    end


    private

    def process run_opts
      @run_opts = run_opts
      cached? ? cached_result : process_and_cache
    end

    def process_and_cache
      log name, :closing_status => (run_opts[:attempt_to_meet] ? true : :dry_run) do
        if run_opts[:callstack].include? self
          log_error "Oh crap, endless loop! (#{run_opts[:callstack].push(self).drop_while {|dep| dep != self }.map(&:name).join(' -> ')})"
        elsif ![:all, uname].include?(opts[:for])
          log_extra "not required on #{uname_str}."
          true
        else
          run_opts[:callstack].push self
          returning process_in_dir do
            run_opts[:callstack].pop
          end
        end
      end
    end

    def process_in_dir
      path = payload[:run_in].is_a?(Symbol) ? vars[payload[:run_in]] : payload[:run_in]
      in_dir path do
        call_task(:setup) and process_deps and process_self
      end
    end

    def process_deps
      @definer.requires_for_system.send(run_opts[:attempt_to_meet] ? :all? : :each, &L{|dep_name|
        unless (dep = Dep(dep_name)).nil?
          returning dep.send :process, run_opts.merge(:parent_vars => vars) do
            run_opts[:child_vars].update dep.vars
          end
        end
      })
    end

    def process_self
      if !(met_result = run_met_task(:initial => true))
        if !run_opts[:attempt_to_meet]
          met_result
        else
          call_task :before and
          returning call_task :meet do call_task :after end
          run_met_task
        end
      elsif :fail == met_result
        log "fail lulz"
      else
        true
      end
    end

    def run_met_task task_opts = {}
      returning cache_process(call_task(:met?)) do |result|
        if :fail == result
          log_extra "You'll have to fix '#{name}' manually."
        elsif !result && task_opts[:initial]
          log_extra "#{name} not already met#{unmet_message_for(result)}."
        elsif result && !task_opts[:initial]
          log "#{name} met.".colorize('green')
        end
      end
    end

    def call_task task_name
      (@definer.send("#{task_name}_for_system") || default_task(task_name)).call
    end

    def default_task task_name
      L{
        send({:met? => :log_extra, :meet => :log_extra}[task_name] || :debug, [
          "#{name} / #{task_name} not defined",
          "#{" for #{uname_str}" unless (payload[task_name] || {})[:all].nil?}",
          {
            :met => ", moving on",
            :meet => " - nothing to do"
          }[task_name],
          "."
        ].join)
        true
      }
    end

    def unmet_message_for result
      unmet_message.nil? || result ? '' : " - #{unmet_message.capitalize}"
    end

    def cached_result
      returning cached_process do |result|
        log_result "#{name} (cached)", :result => result
      end
    end
    def cached?
      instance_variable_defined? :@_cached_process
    end
    def cached_process
      @_cached_process
    end
    def cache_process value
      @_cached_process = value
    end

    def default_run_opts
      {
        :callstack => [],
        :parent_vars => {},
        :child_vars => {}
      }
    end

    def payload
      @definer.payload
    end

    def require_counts
      (payload[:requires] || {}).map {|k,v| "#{k.inspect} => #{v.length}" }.join(', ')
    end

    def inspect
      "#<Dep:#{object_id} '#{name}'#{" #{'un' if cached_result}met" if cached?}, deps = { #{require_counts} }>"
    end
  end
end
