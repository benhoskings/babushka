module Babushka
  class DepError < StandardError
  end
  class Dep
    include PathHelpers
    extend SuggestHelpers

    # This class is used for deps that aren't defined against a meta dep. Using
    # this class with the default values it contains means that the code below
    # can be simpler, because at the code level everything is defined against
    # a 'template' of some sort; some are just BaseTemplate, and some are
    # actual meta deps..
    class BaseTemplate
      def self.suffixed?; false end
      def self.definer_class; BaseDepDefiner end
      def self.runner_class; BaseDepRunner end
    end

    module Helpers
      # Use +spec+ to look up a dep. Because +spec+ might include a source
      # prefix, the dep this method returns could be from any of the currently
      # known sources.
      # If no dep matching +spec+ is found, nil is returned.
      def Dep spec, opts = {}
        Dep.for spec, opts
      end

      # Define and return a dep named +name+, and whose implementation is found
      # in +block+. This is the usual top-level entry point of the babushka
      # DSL (along with +meta+); templated or not, this is how deps are
      # defined.
      def dep name, opts = {}, &block
        Base.sources.current_load_source.deps.add name, opts, block
      end

      # Define and return a meta dep named +name+, and whose implementation is
      # found in +block+. This method, along with +dep, together are the
      # top level of babushka's DSL.
      def meta name, opts = {}, &block
        Base.sources.current_load_source.templates.add name, opts, block
      end

      # TODO remove this after a while. These methods are here to catch calls
      # against the old version of the template DSL, and suggest how they
      # should be upgraded.
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

    # Create a new dep named +name+ within +source+, whose implementation is
    # found in +block+. This method is used internally by DepPool when a dep is
    # added to the pool. To define deps yourself, you should call +dep+ (which
    # is +DepHelpers#dep+).
    def self.make name, source, opts, block
      if /\A[[:print:]]+\z/i !~ name
        raise DepError, "The dep name '#{name}' contains nonprintable characters."
      elsif /\// =~ name
        raise DepError, "The dep name '#{name}' contains '/', which isn't allowed (logs are named after deps, and filenames can't contain '/')."
      elsif /\:/ =~ name
        raise DepError, "The dep name '#{name}' contains ':', which isn't allowed (colons separate dep and template names from source prefixes)."
      else
        new name, source, Base.sources.current_load_opts.merge(opts), block
      end
    end

    # Store the dep's name, implementation, and other details like its source
    # and options. The dep isn't defined if defining has been delayed (i.e. if
    # we're loading from a source).
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

    # Attempt to look up the template this dep was defined against (or if no
    # template was specified, BaseTemplate), and then define the dep against
    # it. If an error occurs, the backtrace point within the dep from which the
    # exception was triggered is logged, as well as the actual exception point.
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

    # Create a definer and runner for this dep from its template, and then
    # process the dep's outer block against the definer.
    #
    # This results in the details of the dep being stored, like the
    # implementation of +met?+ and +meet+, as well as its +requires+ list and
    # any other items defined at the top level.
    def define_dep!
      @runner = template.runner_class.new self
      @definer = template.definer_class.new self, &@block
      definer.define_and_process
      @dep_defined = true
    end

    # Returns true if +#define!+ has aready successfully run on this dep.
    def dep_defined?
      @dep_defined
    end

    # Attempt to retrieve the template specified in +opts[:template]+. If the
    # template name includes a source prefix, it is searched for within the
    # corresponding source. Otherwise, it is searched for in the current source
    # and the core sources.
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

    # Look up the dep specified by +dep_name+, yielding it to the block if it
    # was found.
    #
    # If no such dep exists, search for other similarly spelt deps and re-call
    # this same method on the one chosen by the user, if any.
    def self.find_or_suggest dep_name, &block
      if (dep = Dep(dep_name)).nil?
        log "#{dep_name.to_s.colorize 'grey'} #{"<- this dep isn't defined!".colorize('red')}"
        suggestion = suggest_value_for(dep_name, Base.sources.current_names)
        Dep.context suggestion unless suggestion.nil?
      else
        block.call dep
      end
    end

    # Return this dep's name, first removing the template suffix if one is
    # present.
    #
    # Note that this only removes the suffix when it was used to define the
    # dep. Dep names that end in something that looks like a template suffix,
    # but didn't match a template and result in a templated dep, won't be
    # touched.
    #
    # Some examples:
    #   Dep('benhoskings:Chromium.app').basename #=> 'Chromium'
    #   Dep('generated report.pdf').basename     #=> "generated report.pdf"
    def basename
      suffixed? ? name.sub(/\.#{Regexp.escape(template.name)}$/, '') : name
    end

    # Returns this dep's name, including the source name as a prefix if this
    # dep is in a cloneable source.
    #
    # A cloneable source is one that babushka knows how to automatically
    # update; i.e. a source that babushka could have installed itself.
    #
    # In effect, a cloneable source is one whose deps you prefix when you run
    # them, so this method returns the dep's name in the same form as you would
    # refer to it on the commandline or within a +require+ call in another dep.
    def contextual_name
      dep_source.cloneable? ? "#{dep_source.name}:#{name}" : name
    end

    # Returns the portion of the end of the dep name that looks like a template
    # suffix, if any. Unlike +#basename+, this method will return anything that
    # looks like a template suffix, even if it doesn't match a template.
    def suffix
      name.scan(MetaDepWrapper::TEMPLATE_SUFFIX).flatten.first
    end

    # Entry point for a dry +#process+ run, where only +met?+ blocks will be
    # evaluated.
    #
    # This is useful to inspect the current state of a dep tree, without
    # altering the system. It can cause failures, though, because some deps
    # have requirements that need to be met before the dep can perform its
    # +met?+ check.
    #
    # TODO: In future, there will be support for specifying that in the DSL.
    def met?
      process :dry_run => true, :top_level => true
    end

    # Entry point for a full met?/meet +#process+ run.
    def meet
      process :dry_run => false, :top_level => true
    end

    # Trigger a dep run with this dep at the top of the tree.
    #
    # Running the dep involves the following:
    #   - First, the +setup+ block is run.
    #   - Next, the dep's dependencies (i.e. the contents of +requires+) are
    #     run recursively by calling +#process+ on each; this dep's +#process+
    #     early-exits if any of the subdeps fail.
    #   - Next, the +met?+ block is run. If +met?+ returns:
    #     - +true+, or any true-like value, the dep is already met and there is
    #       nothing to do.
    #     - +:fail+, the dep is considered unmeetable and the run fails.
    #     - Otherwise, the dep is unmet, and the following happens:
    #       - The +prepare+ task is run
    #       - The +before+ task is run
    #       - If +before+ returned a true-like value, the +meet+ task is run.
    #         This is where the actual work of achieving the dep's aim is done.
    #       - If +meet+ returned a true-like value, the +after+ task is run.
    #       - Finally, the +met?+ task is run again, to check whether running
    #         +meet+ has achieved the dep's goal.
    #
    # The final step is important to understand. The +meet+ block is run
    # unconditionally, and its return value is ignored, apart from it
    # determining whether to run the +after+ block. The result of a dep is
    # always taken from its +met?+ block, whether it was already met,
    # unmeetable, or met during the run.
    #
    # Specifically, the following describes the return values of a few
    # components, and of the dep itself.
    #   - A '-' means the corresponding block wouldn't be run at all.
    #   - An 'X' means the corresponding return value doesn't matter, and is
    #     discarded.
    #
    # Initial state   | initial +met?+ | meet  | subsequent +met?+ | dep returns
    # ----------------+----------------+-------+-------------------+------------
    # already met     | true           | -     | -                 | true
    # unmeetable      | :fail          | -     | -                 | false
    # couldn't be met | false          | X     | false             | false
    # met during run  | false          | X     | true              | true
    #
    # Wherever possible, the +met?+ test shouldn't directly test that the
    # +meet+ block performed specific tasks; only that its overall purpose has
    # been achieved. For example, if the purpose of a given dep is to make sure
    # the webserver is running, the contents of the +meet+ block would probably
    # involve `/etc/init.d/nginx start` or similar, on a Linux system at least.
    # In this case, the +met?+ block shouldn't test anything involving
    # `/etc/init.d` directly; instead, it should separately test that the
    # webserver is running, for example by using `netstat` to check that
    # something is listening on port 80.
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
          log_ok "Not required on #{Base.host.differentiator_for opts[:for]}."
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
        Dep.find_or_suggest dep_name do |dep|
          dep.process :parent_source => dep_source
        end
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
      log "#{e.class} at #{e.backtrace.first}:".colorize('red')
      log e.message.colorize('red')
      dep_callpoint = e.backtrace.detect {|l| l[load_path.to_s] } unless load_path.nil?
      log "Check #{dep_callpoint}." unless dep_callpoint.nil? || e.backtrace.first[dep_callpoint]
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
