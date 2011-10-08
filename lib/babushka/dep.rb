module Babushka

  class UnmeetableDep < RuntimeError
  end
  class DepDefinitionError < ArgumentError
  end
  class InvalidDepName < DepDefinitionError
  end
  class TemplateNotFound < DepDefinitionError
  end
  class DepParameterError < DepDefinitionError
  end
  class DepArgumentError < DepDefinitionError
  end

  class Dep
    include LogHelpers
    extend LogHelpers
    include PathHelpers
    extend SuggestHelpers

    # This class is used for deps that aren't defined against a meta dep. Using
    # this class with the default values it contains means that the code below
    # can be simpler, because at the code level everything is defined against
    # a 'template' of some sort; some are just BaseTemplate, and some are
    # actual meta deps.
    class BaseTemplate
      def self.contextual_name; name end
      def self.suffixed?; false end
      def self.context_class; DepContext end
    end

    class Requirement < Struct.new(:name, :args)
    end

    attr_reader :name, :params, :args, :opts, :vars, :dep_source, :load_path
    attr_accessor :result_message

    # Create a new dep named +name+ within +source+, whose implementation is
    # found in +block+. To define deps yourself, you should call +dep+ (which
    # is +Dep::Helpers#dep+).
    def initialize name, source, params, opts, block
      if name.empty?
        raise InvalidDepName, "Deps can't have empty names."
      elsif /\A[[:print:]]+\z/i !~ name
        raise InvalidDepName, "The dep name '#{name}' contains nonprintable characters."
      elsif /\// =~ name
        raise InvalidDepName, "The dep name '#{name}' contains '/', which isn't allowed (logs are named after deps, and filenames can't contain '/')."
      elsif /\:/ =~ name
        raise InvalidDepName, "The dep name '#{name}' contains ':', which isn't allowed (colons separate dep and template names from source prefixes)."
      elsif !params.all? {|param| param.is_a?(Symbol) }
        non_symbol_params = params.reject {|p| p.is_a?(Symbol) }
        raise DepParameterError, "The dep '#{name}' has #{'a ' if non_symbol_params.length == 1}non-symbol param#{'s' if non_symbol_params.length > 1} #{non_symbol_params.map(&:inspect).to_list}, which #{non_symbol_params.length == 1 ? "isn't" : "aren't"} allowed."
      else
        @name = name.to_s
        @params = params
        @args = {}
        @opts = Base.sources.current_load_opts.merge(opts)
        @block = block
        @dep_source = source
        @load_path = Base.sources.current_load_path
        @dep_source.deps.register self
        assign_template if Base.sources.current_real_load_source.nil?
        @dep_defined = @_cached_process = nil # false represents failure for these two.
      end
    end

    def context
      define! if @context.nil?
      @context
    end

    def template
      assign_template if @template.nil?
      @template
    end

    # Returns true if +#define!+ has aready successfully run on this dep.
    def dep_defined?
      @dep_defined
    end

    # Look up the dep specified by +dep_name+, yielding it to the block if it
    # was found.
    #
    # If no such dep exists, search for other similarly spelt deps and re-call
    # this same method on the one chosen by the user, if any.
    def self.find_or_suggest dep_name, opts = {}, &block
      if (dep = Dep(dep_name, opts)).nil?
        log "#{dep_name.to_s.colorize 'grey'} #{"<- this dep isn't defined!".colorize('red')}"
        suggestion = suggest_value_for(dep_name, Base.sources.current_names)
        Dep.find_or_suggest suggestion, opts, &block unless suggestion.nil?
      elsif block.nil?
        dep
      else
        block.call dep
      end
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

    # Returns the portion of the end of the dep name that looks like a template
    # suffix, if any. Unlike +#basename+, this method will return anything that
    # looks like a template suffix, even if it doesn't match a template.
    def suffix
      name.scan(MetaDep::TEMPLATE_NAME_MATCH).flatten.first
    end

    def with *args
      @args = if args.map(&:class) == [Hash]
        parse_named_arguments(args.first)
      else
        parse_positional_arguments(args)
      end.map_values {|k,v|
        Parameter.for(k, v)
      }
      self
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
    def met? *args
      with(*args).process :dry_run => true, :top_level => true
    end

    # Entry point for a full met?/meet +#process+ run.
    def meet *args
      with(*args).process :dry_run => false, :top_level => true
    end

    # Trigger a dep run with this dep at the top of the tree.
    #
    # Running the dep involves the following:
    # - First, the +setup+ block is run.
    # - Next, the dep's dependencies (i.e. the contents of +requires+) are
    #   run recursively by calling +#process+ on each; this dep's +#process+
    #   early-exits if any of the subdeps fail.
    # - Next, the +met?+ block is run. If +met?+ returns +true+, or any
    #   true-like value, the dep is already met and there is nothing to do.
    #   Otherwise, the dep is unmet, and the following happens:
    #     - The +prepare+ task is run
    #     - The +before+ task is run
    #     - If +before+ returned a true-like value, the +meet+ task is run.
    #       This is where the actual work of achieving the dep's aim is done.
    #     - If +meet+ returned a true-like value, the +after+ task is run.
    #     - Finally, the +met?+ task is run again, to check whether running
    #       +meet+ has achieved the dep's goal.
    #
    # The final step is important to understand. The +meet+ block is run
    # unconditionally, and its return value is ignored, apart from it
    # determining whether to run the +after+ block. The result of a dep is
    # always taken from its +met?+ block, whether it was already met,
    # unmeetable, or met during the run.
    #
    # Sometimes there are conditions under which a dep can't be met. For
    # example, if a dep detects that the existing version of a package is
    # broken in some way that requires manual intervention, then there's no
    # use running the +meet+ block. In this circumstance, you can call
    # +#unmeetable+, which raises an +UnmeetableDep+ exception. Babushka will
    # rescue it and consider the dep unmeetable (that is, it will just allow
    # the dep to fail without attempting to meet it).
    #
    # The following describes the return values of a few components, and of
    # the dep itself.
    # - A '-' means the corresponding block wouldn't be run at all.
    # - An 'X' means the corresponding return value doesn't matter, and is
    #   discarded.
    #
    #     Initial state   | initial met?         | meet  | subsequent met? | dep returns
    #     ----------------+----------------------+-------+-----------------+------------
    #     already met     | true                 | -     | -               | true
    #     unmeetable      | UnmeetableDep raised | -     | -               | false
    #     couldn't be met | false                | X     | false           | false
    #     met during run  | false                | X     | true            | true
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
    def process with_opts = {}
      task.opts.update with_opts
      (cached? ? cached_result : process_and_cache).tap {
        Base.sources.uncache! if with_opts[:top_level]
      }
    end

    private

    def define_or_complain!
      @dep_defined = begin
        define!
      rescue StandardError => e
        log_exception_in_dep(e)
        false
      end
    end

    # Attempt to look up the template this dep was defined against (or if no
    # template was specified, BaseTemplate), and then define the dep against
    # it. If an error occurs, the backtrace point within the dep from which the
    # exception was triggered is logged, as well as the actual exception point.
    def define!
      if dep_defined?
        debug "#{name}: already defined."
      elsif dep_defined? == false
        debug "#{name}: defining already failed."
      elsif template
        debug "(defining #{name} against #{template.contextual_name})"
        define_dep!
      end
      dep_defined?
    end

    # Create a context for this dep from its template, and then process the
    # dep's outer block in that context.
    #
    # This results in the details of the dep being stored, like the
    # implementation of +met?+ and +meet+, as well as its +requires+ list and
    # any other items defined at the top level.
    def define_dep!
      @context = template.context_class.new self, &@block
      context.define!
      @dep_defined = true
    end

    # Attempt to retrieve the template specified in +opts[:template]+. If the
    # template name includes a source prefix, it is searched for within the
    # corresponding source. Otherwise, it is searched for in the current source
    # and the core sources.
    def assign_template
      @template = if opts[:template]
        Base.sources.template_for(opts[:template], :from => dep_source).tap {|t|
          raise TemplateNotFound, "There is no template named '#{opts[:template]}' to define '#{name}' against." if t.nil?
        }
      else
        Base.sources.template_for(suffix, :from => dep_source) || self.class.base_template
      end
    end

    def self.base_template
      BaseTemplate
    end

    def parse_named_arguments args
      if (non_symbol = args.keys.reject {|key| key.is_a?(Symbol) }).any?
        # We sort here so we can spec the exception message across different rubies.
        non_symbol = non_symbol.sort_by(&:to_s)
        raise DepArgumentError, "The dep '#{name}' received #{'a ' if non_symbol.length == 1}non-symbol argument#{'s' if non_symbol.length > 1} #{non_symbol.map(&:inspect).to_list}."
      elsif (unexpected = args.keys - params).any?
        unexpected = unexpected.sort_by(&:to_s)
        raise DepArgumentError, "The dep '#{name}' received #{'an ' if unexpected.length == 1}unexpected argument#{'s' if unexpected.length > 1} #{unexpected.map(&:inspect).to_list}."
      end
      args
    end

    def parse_positional_arguments args
      if !args.empty? && args.length != params.length
        raise DepArgumentError, "The dep '#{name}' accepts #{params.length} argument#{'s' unless params.length == 1}, but #{args.length} #{args.length == 1 ? 'was' : 'were'} passed."
      end
      params.inject({}) {|hsh,param| hsh[param] = args.shift; hsh }
    end

    def process_and_cache
      log logging_name, :closing_status => (task.opt(:dry_run) ? :dry_run : true) do
        if dep_defined? == false
          # Only log about define errors if the define previously failed...
          log_error "This dep isn't defined. Perhaps there was a load error?"
        elsif !define_or_complain!
          # ... not if it failed as part of this process, since that should log anyway.
        elsif task.callstack.include? self
          log_error "Oh crap, endless loop! (#{task.callstack.push(self).drop_while {|dep| dep != self }.map(&:name).join(' -> ')})"
        elsif !opts[:for].nil? && !Base.host.matches?(opts[:for])
          log_ok "Not required on #{Base.host.differentiator_for opts[:for]}."
        else
          task.callstack.push self
          process_this_dep.tap {
            task.callstack.pop
          }
        end
      end
    end

    def process_this_dep
      process_task(:setup)
      process_deps and process_self
    rescue UnmeetableDep => e
      log_error e.message
      log "I don't know how to fix that, so it's up to you. :)"
      nil
    rescue StandardError => e
      log_exception_in_dep e
      Base.task.reportable = e.is_a?(DepDefinitionError)
      nil
    end

    def process_deps accessor = :requires
      requirements_for(accessor).send(task.opt(:dry_run) ? :each : :all?) do |requirement|
        Dep.find_or_suggest requirement.name, :from => dep_source do |dep|
          dep.with(*requirement.args).process
        end
      end
    end

    def process_self
      cd context.run_in do
        process_met_task(:initial => true) {
          if task.opt(:dry_run)
            false # unmet
          else
            process_task(:prepare)
            if !process_deps(:requires_when_unmet)
              false # install-time deps unmet
            else
              log 'meet' do
                process_task(:before) and process_task(:meet) and process_task(:after)
              end
              process_met_task
            end
          end
        }
      end
    end

    def process_met_task task_opts = {}, &block
      # Explicitly return false to distinguish unmet deps from failed
      # ones -- those return nil.
      run_met_task(task_opts) || block.try(:call) || false
    end

    def run_met_task task_opts = {}
      cache_process(process_task(:met?)).tap {|result|
        log result_message, :as => (:error unless result || task_opts[:initial]) unless result_message.nil?
        self.result_message = nil
      }
    end

    def process_task task_name
      # log "calling #{name} / #{task_name}"
      track_block_for(task_name) if Base.task.opt(:track_blocks)
      context.instance_eval(&context.send(task_name))
    end

    def requirements_for list_name
      context.send(list_name).map {|dep_or_requirement|
        if dep_or_requirement.is_a?(Requirement)
          dep_or_requirement
        else
          Requirement.new(dep_or_requirement, [])
        end
      }
    end

    def logging_name
      if Base.task.opt(:debug)
        "#{contextual_name}(#{args.values.map(&:description).join(', ')})"
      else
        contextual_name
      end
    end

    def log_exception_in_dep e
      log_error e.message
      advice = e.is_a?(DepDefinitionError) ? "Looks like a problem with '#{name}' - check" : "Check"
      log "#{advice} #{(e.backtrace.detect {|l| l[load_path.to_s] } || load_path).sub(/\:in [^:]+$/, '')}." unless load_path.nil?
      debug e.backtrace * "\n"
    end

    def track_block_for task_name
      if context.has_block? task_name
        file, line = *context.file_and_line_for(task_name)
        shell "mate '#{file}' -l #{line}" unless file.nil? || line.nil?
        sleep 2
      end
    end

    def cached_result
      cached_process.tap {|result|
        if result
          log "#{Logging::TickChar} #{name} (cached)".colorize('green')
        elsif task.opt(:dry_run)
          log "~ #{name} (cached)".colorize('blue')
        else
          log "#{Logging::CrossChar} #{name} (cached)".colorize('red')
        end
      }
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
      !opts[:template] && template != BaseTemplate
    end

    def payload
      context.payload
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
        "#{"(#{'un' unless cached_process}met) " if cached?}<- [#{context.requires.join(', ')}]"
      else
        "(not defined yet)"
      end
    end
  end
end
