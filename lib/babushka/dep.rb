module Babushka
  class DepError < StandardError
  end
  class Dep
    module Helpers
      def Dep spec;                    Dep.for spec end
      def dep name, opts = {}, &block; DepDefiner.current_load_source.deps.add name, opts, block, BaseDepDefiner, BaseDepRunner end
      def meta name, opts = {}, &block; MetaDepWrapper.for name, opts, &block end
      def pkg name, opts = {}, &block; DepDefiner.current_load_source.deps.add name, opts, block, PkgDepDefiner , PkgDepRunner  end
      def gem name, opts = {}, &block; DepDefiner.current_load_source.deps.add name, opts, block, GemDepDefiner , GemDepRunner  end
      def ext name, opts = {}, &block; DepDefiner.current_load_source.deps.add name, opts, block, ExtDepDefiner , ExtDepRunner  end
    end

    attr_reader :name, :opts, :vars, :definer, :runner, :dep_source
    attr_accessor :unmet_message

    delegate :desc, :to => :definer
    delegate :set, :merge, :define_var, :to => :runner

    def self.make name, source, in_opts, block, definer_class, runner_class
      if /\A[[:print:]]+\z/i !~ name
        raise DepError, "The dep name '#{name}' contains nonprintable characters."
      elsif /\// =~ name
        raise DepError, "The dep name '#{name}' contains '/', which isn't allowed."
      else
        new name, source, in_opts, block, definer_class, runner_class
      end
    end

    def initialize name, source, in_opts, block, definer_class, runner_class
      @name = name.to_s
      @opts = {
        :for => :all
      }.merge in_opts
      @vars = {}
      @runner = runner_class.new self
      @definer = definer_class.new self, &block
      definer.define_and_process
      debug "\"#{name}\" depends on #{payload[:requires].inspect}"
      @dep_source = source
      @load_path = DepDefiner.current_load_path
      source.register self
    end

    def self.for dep_spec_input
      dep_spec = dep_spec_input.respond_to?(:name) ? dep_spec_input.name : dep_spec_input
      if dep_spec[/:/]
        source_name, dep_name = dep_spec.split(':', 2)
        Source.for(source_name).find(dep_name)
      else
        matches = Source.all_sources.map {|source| source.find(dep_spec) }.flatten.compact
        if matches.length == 1
          matches.first
        else
          log "More than one source (#{matches.map(&:dep_source).map(&:name).join(',')}) contain a dep called '#{dep_name}'."
        end
      end
    end

    extend Suggest::Helpers

    def self.process dep_name
      if (dep = Dep(dep_name)).nil?
        log "#{dep_name.to_s.colorize 'grey'} #{"<- this dep isn't defined!".colorize('red')}"
        log "You don't have any dep sources added, so there will be minimal deps available.\nCheck 'babushka help sources' and the 'dep source' dep." if Source.count.zero?
        suggestion = suggest_value_for(dep_name, Dep.pool.names)
        Dep.process suggestion unless suggestion.nil?
      else
        dep.process
      end
    end

    def met?
      process :dry_run => true, :top_level => true
    end
    def meet
      process :dry_run => false, :top_level => true
    end

    def process with_run_opts = {}
      task.run_opts.update with_run_opts
      returning cached? ? cached_result : process_and_cache do
        Dep.pool.uncache! if with_run_opts[:top_level]
      end
    end

    private

    def process_and_cache
      log name, :closing_status => (task.opt(:dry_run) ? :dry_run : true) do
        if task.callstack.include? self
          log_error "Oh crap, endless loop! (#{task.callstack.push(self).drop_while {|dep| dep != self }.map(&:name).join(' -> ')})"
        elsif !host.matches?(opts[:for])
          log_ok "Not required on #{host.differentiator_for opts[:for]}."
        else
          task.callstack.push self
          returning process_in_dir do
            task.callstack.pop
          end
        end
      end
    end

    def process_in_dir
      path = payload[:run_in].is_a?(Symbol) ? vars[payload[:run_in]] : payload[:run_in]
      in_dir path do
        process_task(:internal_setup)
        process_task(:setup)
        process_deps and process_self
      end
    end

    def process_deps accessor = :requires
      definer.send(accessor).send(task.opt(:dry_run) ? :each : :all?, &L{|dep_name|
        Dep.process dep_name
      })
    end

    def process_self
      process_met_task(:initial => true) {
        if task.opt(:dry_run)
          false # unmet
        else
          process_task(:prepare)
          if !process_deps(:requires_when_unmet)
            false # install-time deps unmet
          else
            process_task(:before) and process_task(:meet) and process_task(:after)
            process_met_task
          end
        end
      }
    end

    def process_met_task task_opts = {}, &block
      if !(met_result = run_met_task(task_opts))
        if block.nil?
          false # unmet
        else
          block.call
        end
      elsif :fail == met_result
        false # can't be met
      else
        true # already met
      end
    end

    def run_met_task task_opts = {}
      returning cache_process(call_task(:met?)) do |result|
        if :fail == result
          log "I don't know how to fix that, so it's up to you. :)"
        elsif !result && !Base.task.opt(:dry_run)
          if task_opts[:initial]
            log "not already met#{unmet_message_for(result)}."
          else
            log_error "couldn't meet#{unmet_message_for(result)}."
          end
        elsif result && !task_opts[:initial]
          log "#{name} met.".colorize('green')
        end
      end
    end

    def process_task task_name
      !call_task(task_name).in? [nil, false, :fail]
    end

    def call_task task_name
      # log "calling #{name} / #{task_name}"
      track_block_for(task_name) if Base.task.opt(:track_blocks)
      runner.instance_eval &definer.send(task_name)
    rescue StandardError => e
      log "#{e.class} during '#{name}' / #{task_name}{}.".colorize('red')
      log "#{e.backtrace.first}: #{e.message}".colorize('red')
      dep_callpoint = e.backtrace.detect {|l| l[definer.source_path.to_s] } unless definer.source_path.nil?
      log "Check #{dep_callpoint}." unless dep_callpoint.nil?
      debug e.backtrace * "\n"
      Base.task.reportable = true
      :fail
    end

    include Shell::Helpers
    def track_block_for task_name
      if definer.has_task?(task_name)
        file, line = *definer.send(task_name).inspect.scan(/\#\<Proc\:0x[0-9a-f]+\@([^:]+):(\d+)>/).flatten
        shell "mate '#{file}' -l #{line}" unless file.nil? || line.nil?
        sleep 2
      end
    end

    def unmet_message_for result
      unmet_message.nil? || result ? '' : " - #{unmet_message}"
    end

    def cached_result
      returning cached_process do |result|
        log_result "#{name} (cached)", :result => result, :as_bypass => task.opt(:dry_run)
      end
    end
    def cached?
      !@_cached_process.nil?
    end
    def uncache!
      @_cached_process = nil
    end
    def cached_process
      @_cached_process
    end
    def cache_process value
      @_cached_process = (value.nil? ? false : value)
    end

    def payload
      definer.payload
    end

    def task
      Base.task
    end

    public

    def inspect
      "#<Dep:#{object_id} '#{name}'#{" (#{'un' if cached_process}met)" if cached?} <- [#{definer.requires.map(&:name).join(', ')}]>"
    end
  end
end
