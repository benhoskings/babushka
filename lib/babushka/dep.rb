module Babushka
  class DepError < StandardError
  end
  class Dep
    class BaseTemplate
      def self.suffixed?; false end
      def self.definer_class; BaseDepDefiner end
      def self.runner_class; BaseDepRunner end
    end

    module Helpers
      def Dep spec, opts = {};         Dep.for spec, opts end
      def dep name, opts = {}, &block; Base.sources.current_load_source.deps.add name, opts, block end
      def meta name, opts = {}, &block; Base.sources.current_load_source.templates.add name, opts, block end

      # TODO remove this after a while
      %w[pkg managed src app font installer tmbundle dl nginx apache2 vim_plugin lighttpd_module gem_source security_apt_source plist_default pathogen_plugin_source pathogen_link_exists].each {|meta|
        define_method meta do |*args|
          name = args.first
          new_meta = {'pkg' => 'managed'}[meta] || meta
          log_error "#{caller.first.sub(/\:in [^:]+$/, '')}: This syntax isn't valid any more:"
          log "  #{meta} '#{name}'"
          log_error "Instead, you should use one of these:"
          log "  dep '#{name.end_with(".#{new_meta}")}'"
          log "  dep '#{name.chomp(".#{new_meta}")}', :template => '#{new_meta}'"
          log ""
        end
      }
    end

    attr_reader :name, :opts, :vars, :template, :definer, :runner, :dep_source, :load_path
    attr_accessor :unmet_message

    delegate :desc, :to => :definer
    delegate :set, :merge, :define_var, :to => :runner

    def self.make name, source, opts, block
      if /\A[[:print:]]+\z/i !~ name
        raise DepError, "The dep name '#{name}' contains nonprintable characters."
      elsif /\// =~ name
        raise DepError, "The dep name '#{name}' contains '/', which isn't allowed."
      else
        new name, source, Base.sources.current_load_opts.merge(opts), block
      end
    end

    def initialize name, source, in_opts, block
      @name = name.to_s
      @opts = in_opts.defaults :for => :all
      @block = block
      @vars = {}
      @dep_source = source
      @load_path = Base.sources.current_load_path
      @dep_source.deps.register self
      define! unless opts[:delay_defining]
    end

    def define!
      assign_template
      begin
        define_dep!
      rescue Exception => e
        log_error "#{e.backtrace.first}: #{e.message}"
        log "Check #{(e.backtrace.detect {|l| l[load_path.to_s] } || load_path).sub(/\:in [^:]+$/, '')}." unless load_path.nil?
        debug e.backtrace * "\n"
      end
    end

    def define_dep!
      @runner = template.runner_class.new self
      @definer = template.definer_class.new self, &@block
      definer.define_and_process
      @dep_defined = true
    end

    def dep_defined?
      @dep_defined
    end

    def assign_template
      @template = if opts[:template]
        returning Base.sources.template_for(opts[:template], :from => Base.sources.current_load_source) do |t|
          raise DepError, "There is no template named '#{opts[:template]}' to define '#{name}' against." if t.nil?
        end
      else
        returning Base.sources.template_for(suffix, :from => Base.sources.current_load_source) || BaseTemplate do |t|
          opts[:suffixed] = (t != BaseTemplate)
        end
      end
    end

    def self.for dep_spec, opts = {}
      Base.sources.dep_for(
        dep_spec.respond_to?(:name) ? dep_spec.name : dep_spec.to_s,
        :from => opts[:parent_source]
      )
    end

    extend Suggest::Helpers

    def self.process dep_name, with_run_opts = {}
      if (dep = Dep(dep_name, with_run_opts)).nil?
        log "#{dep_name.to_s.colorize 'grey'} #{"<- this dep isn't defined!".colorize('red')}"
        suggestion = suggest_value_for(dep_name, Base.sources.current_names)
        Dep.process suggestion, with_run_opts unless suggestion.nil?
      else
        dep.process with_run_opts
      end
    end

    def basename
      suffixed? ? name.sub(/\.#{Regexp.escape(template.name)}$/, '') : name
    end

    def suffix
      name.scan(MetaDepWrapper::TEMPLATE_SUFFIX).flatten.first
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
        Base.sources.uncache! if with_run_opts[:top_level]
      end
    end

    private

    def process_and_cache
      log contextual_name, :closing_status => (task.opt(:dry_run) ? :dry_run : true) do
        if !dep_defined?
          log_error "This dep isn't defined. Perhaps there was a load error?"
        elsif task.callstack.include? self
          log_error "Oh crap, endless loop! (#{task.callstack.push(self).drop_while {|dep| dep != self }.map(&:name).join(' -> ')})"
        elsif !Base.host.matches?(opts[:for])
          log_ok "Not required on #{host.differentiator_for opts[:for]}."
        else
          task.callstack.push self
          returning process_this_dep do
            task.callstack.pop
          end
        end
      end
    end

    def process_this_dep
      process_task(:internal_setup)
      process_task(:setup)
      process_deps and process_self
    end

    def process_deps accessor = :requires
      definer.send(accessor).send(task.opt(:dry_run) ? :each : :all?, &L{|dep_name|
        Dep.process dep_name, :parent_source => dep_source
      })
    end

    def process_self
      path = definer.run_in.empty? ? nil : definer.run_in.first.to_s
      in_dir path do
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
      dep_callpoint = e.backtrace.detect {|l| l[load_path.to_s] } unless load_path.nil?
      log "Check #{dep_callpoint}." unless dep_callpoint.nil?
      debug e.backtrace * "\n"
      Base.task.reportable = true
      :fail
    end

    def track_block_for task_name
      if definer.has_task?(task_name)
        file, line = *definer.send(task_name).inspect.scan(/\#\<Proc\:0x[0-9a-f]+\@([^:]+):(\d+)>/).flatten
        shell "mate '#{file}' -l #{line}" unless file.nil? || line.nil?
        sleep 2
      end
    end

    def contextual_name
      dep_source.cloneable? ? "#{dep_source.name}:#{name}" : name
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

    def suffixed?
      opts[:suffixed]
    end

    def payload
      definer.payload
    end

    def task
      Base.task
    end

    public

    def inspect
      "#<Dep:#{object_id} #{"#{dep_source.name}:" unless dep_source.nil?}'#{name}' #{defined_info}>"
    end

    def defined_info
      if dep_defined?
        "#{"(#{'un' unless cached_process}met) " if cached?}<- [#{definer.requires.map(&:name).join(', ')}]"
      else
        "(not defined yet)"
      end
    end
  end
end
