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

  # A DepRequirement is a representation of a dep being called - its name,
  # along with the arguments that will be passed to it.
  #
  # DepRequirement is used internally by babushka when deps are required with
  # arguments using "name".with(args). This allows babushka to delay loading
  # the dep in question until the moment it's called.
  class DepRequirement < Struct.new(:name, :args)
  end


  class Dep
    include LogHelpers
    extend LogHelpers

    attr_reader :name, :params, :args, :opts, :dep_source, :load_path, :callstack

    # Create a new dep named +name+ within +source+, whose implementation is
    # found in +block+. To define deps yourself, you should call +dep+ (which
    # is +Dep::Helpers#dep+).
    def initialize name, source, params, opts, block
      if !name.is_a?(String)
        raise InvalidDepName, "The dep name #{name.inspect} isn't a string."
      elsif name.empty?
        raise InvalidDepName, "Deps can't have empty names."
      elsif /[[:cntrl:]]/mu =~ name
        raise InvalidDepName, "The dep name '#{name}' contains nonprintable characters."
      elsif /\// =~ name
        raise InvalidDepName, "The dep name '#{name}' contains '/', which isn't allowed (logs are named after deps, and filenames can't contain '/')."
      elsif /\:/ =~ name
        raise InvalidDepName, "The dep name '#{name}' contains ':', which isn't allowed (colons separate dep and template names from source prefixes)."
      elsif !params.all? {|param| param.is_a?(Symbol) }
        non_symbol_params = params.reject {|p| p.is_a?(Symbol) }
        raise DepParameterError, "The dep '#{name}' has #{'a ' if non_symbol_params.length == 1}non-symbol param#{'s' if non_symbol_params.length > 1} #{non_symbol_params.map(&:inspect).to_list}, which #{non_symbol_params.length == 1 ? "isn't" : "aren't"} allowed."
      else
        @name, @dep_source, @params, @block = name, source, params, block
        @args = {}
        @opts = Base.sources.current_load_opts.merge(opts)
        @load_path = Base.sources.current_load_path
        @dep_source.deps.register(self)
      end
    end

    def context
      @context ||= template.context_class.new(self, &@block)
    end

    # Attempt to retrieve the template specified in +opts[:template]+. If the
    # template name includes a source prefix, it is searched for within the
    # corresponding source. Otherwise, it is searched for in the current source
    # and the core sources.
    def template
      @template ||= if opts[:template]
        Base.sources.template_for(opts[:template], :from => dep_source).tap {|t|
          raise TemplateNotFound, "There is no template named '#{opts[:template]}' to define '#{name}' against." if t.nil?
        }
      else
        Base.sources.template_for(suffix, :from => dep_source) || self.class.base_template
      end
    end

    # Returns this dep's name, including its source name as a prefix if the
    # source is remote.
    #
    # The contextual name is the name you can use to refer to unambiguously
    # refer to this dep on your system; i.e. the name that properly identifies
    # the dep, taking your (possibly customised) source names into account.
    def contextual_name
      dep_source.remote? ? "#{dep_source.name}:#{name}" : name
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
      name.scan(DepTemplate::TEMPLATE_NAME_MATCH).flatten.first
    end

    def cache_key
      DepRequirement.new(name, @params.map {|p| @args[p].try(:current_value) })
    end

    def with *args
      @args = parse_arguments(args)
      @context = nil # To re-run param.default() calls, etc, inside deps.
      self
    end

    # The entry point for a dry run, where only +met?+ blocks will be
    # evaluated. This is useful to inspect the current state of a dep tree,
    # without altering the system.
    def met? *args
      with(*args).process(false)
    end

    # Entry point for a full met?/meet +#process+ run.
    def meet *args
      with(*args).process(true)
    end

    # Run this dep and its subdeps recursively.
    #
    # The overall flow for a single dep is [met? [, meet, met?]]. That is,
    # met? is checked; if it's false, meet is run and then met? is checked
    # again.
    #
    # The [meet, met?] component for unmet deps is only performed if +and_meet+
    # is true. If it's false, then babushka will just check met? down the tree,
    # returning true if this dep and all its subdeps are already met.
    #
    # Running the dep involves the following steps:
    # - First, the +setup+ block is run.
    # - Next, the dep's dependencies (i.e. the contents of +requires+) are
    #   run recursively; this dep early-exits if any of the subdeps couldn't be
    #   met (or if this is a dry run, if any of the subdeps are unmet).
    # - If the dependencies are all met, the +met?+ block is run. If +met?+
    #   returns +true+, or any true-like value, the dep is already met and
    #   there is nothing to do. Otherwise, the dep is unmet, and the following
    #   happens:
    #     - The +prepare+ task is run.
    #     - The +before+ task is run.
    #     - If +before+ returned a true-like value, the +meet+ task is run.
    #       This is where the actual work of achieving the dep's aim is done.
    #     - If +meet+ returned a true-like value, the +after+ task is run.
    # - Finally, the +met?+ task is run again, to check whether running +meet+
    #   achieved the dep's goal.
    #
    # The final step is important to understand: the +before+/+meet+/+after+
    # blocks' return values are ignored. The result of a dep is always that of
    # its +met?+ block, whether it was already met, became met after the meet
    # block was run, or couldn't be met.
    #
    # Sometimes there are conditions under which a dep is unmeetable. For
    # example, if a dep detects that the existing version of a package is
    # broken in some way that requires manual intervention, then there's no
    # use running the +meet+ block. In this circumstance, the dep can call
    # +#unmeetable!+, which raises an +UnmeetableDep+ exception. Babushka will
    # rescue it and consider the dep unmeetable (that is, it will just allow
    # the dep to fail without attempting to meet it).
    #
    # The following describes the return values of the defining components, and
    # of the dep itself.
    # - A '-' means the corresponding block wouldn't be run at all.
    # - An 'X' means the corresponding value doesn't matter, and is discarded.
    #
    #     Scenario            | met?         | -> meet      | -> met? | dep returns
    #     --------------------+--------------+--------------+---------+------------
    #     already met         | true         | -            | -       | true
    #     met during run      | false        | X            | true    | true
    #     couldn't be met     | false        | X            | false   | false
    #     failure during meet | false        | #unmeetable! | -       | nil
    #     unmeetable          | #unmeetable! | -            | -       | nil
    #
    # Wherever possible, the +met?+ test shouldn't directly test any work done
    # in the +meet+ block, only that its overall purpose has been achieved.
    # Just like normal test-driven development, you should test the "what" and
    # not the "how". Tests involving the "how" are brittle and don't correctly
    # express the dep's intent.
    #
    # For example, if the purpose of a given dep is to make sure the webserver
    # is running, the contents of the +meet+ block would probably involve
    # `/etc/init.d/nginx start` or similar, on a Linux system at least. In this
    # case, the +met?+ block shouldn't test anything involving `/etc/init.d`
    # directly; instead, it should separately test that the webserver is
    # running, for example by using `lsof` to check that something is listening
    # on port 80.
    def process and_meet = true
      process_as_requirement(and_meet, [], Babushka::DepCache.new)
    end

    # Process this dep as a requirement of another dep -- that is, not as the
    # top-level dep in a tree. The difference is that the callstack and dep
    # cache are supplied by the calling dep, instead of created anew.
    #
    # This method is intended to be called only from deps themselves, as they
    # invoke their requirements (via Dep#run_requirement); to process a
    # dep directly, call Dep#process instead.
    def process_as_requirement and_meet, callstack, cache
      @callstack = callstack
      @cache = cache
      process_with_caching(and_meet)
    ensure
      @callstack = @cache = nil
    end

    private

    attr_reader :cache

    def self.base_template
      Babushka::BaseTemplate
    end

    # A hash of argument names to Parameter instances representing the
    # arguments that were supplied. Parameters for which no argument was
    # passed are still present, but contain no value, and will lazily prompt
    # for it as required.
    def parse_arguments args
      if args.map(&:class) == [Hash]
        parse_named_arguments(args.first)
      else
        parse_positional_arguments(args)
      end.map_values {|k,v|
        Parameter.for(k, v)
      }
    end

    # Parse arguments supplied as a hash (i.e. argument names to values). When
    # passing dep arguments by name, they can be included or ommitted as
    # required.
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

    # Parse arguments supplied positionally, as an array of values, When
    # passing dep arguments positionally, they must all be included.
    def parse_positional_arguments args
      if !args.empty? && args.length != params.length
        raise DepArgumentError, "The dep '#{name}' accepts #{params.length} argument#{'s' unless params.length == 1}, but #{args.length} #{args.length == 1 ? 'was' : 'were'} passed."
      end
      Hash[params.zip(args)]
    end

    # Process this dep using a pre-existing cache. The cache is used during
    # the run to avoid running deps (and their subtrees) more than once with
    # the same arguments.
    def process_with_caching and_meet
      cache.read(
        cache_key, :hit => lambda {|value| log_cached(value, and_meet) }
      ) {
        process!(and_meet)
      }
    end

    # This is the top-level entry point for processing a dep, disregarding
    # caching. This method is here to do some housekeeping around the actual
    # dep logic:
    #   - It detects when the dep can't be run (if it failed to define, or if
    #     running it would cause an endless loop);
    #   - It detects when the dep shouldn't be run (if it's not intended for
    #     a system of the type we're running on);
    #   - It wraps this dep's logging in a level of indentation with its name;
    #   - It rescues exceptions that happen during the run so that we can
    #     fail with dignity.
    def process! and_meet
      log logging_name, :closing_status => (and_meet ? true : :dry_run) do
        if context.failed?
          log_error "This dep previously failed to load."
        elsif callstack.include?(self)
          log_error "Oh crap, endless loop! (#{callstack.push(self).drop_while {|dep| dep != self }.map(&:name).join(' -> ')})"
        elsif !opts[:for].nil? && !Babushka.host.matches?(opts[:for])
          log_ok "Not required on #{Babushka.host.differentiator_for opts[:for]}."
        else
          callstack.push(self)
          run_met_stage(and_meet).tap {
            callstack.pop
          }
        end
      end
    rescue UnmeetableDep => e
      log_error(e.message)
      log "I don't know how to fix that, so it's up to you. :)"
      nil
    rescue StandardError => e
      log_exception_in_dep(e)
      nil
    end

    # Both the met? and meet stages involve preparation, dependencies, and
    # the stage itself. For met?, we setup, ensure all the dep's requirements
    # are met, and then call #run_met to run the met? check. (If the dep is
    # unmet and should be met, #run_met will do that too.)
    def run_met_stage and_meet
      invoke(:setup)
      run_requirements(:requires, and_meet) && run_met(and_meet)
    end

    # Check if this dep is met. If it's not and we should attempt to meet it,
    # then run that stage, and then check again whether the dep is met (i.e.
    # whether running the meet stage met the dep).
    def run_met and_meet
      if invoke(:met?)
        true # already met.
      elsif and_meet
        run_meet_stage
        invoke(:met?)
      end
    end

    # The equivalent of #run_met_stage for meeting the dep: prepare, ensure
    # unmet-only requirements are met, and then call #run_meet to meet the dep.
    def run_meet_stage
      invoke(:prepare)
      run_requirements(:requires_when_unmet, true) && run_meet
    end

    # Unconditionally attempt to meet this dep. (This method does return the
    # result of attempting to meet the dep, but the value is ignored by
    # #run_met.)
    def run_meet
      log('meet') { invoke(:before) && invoke(:meet) && invoke(:after) }
    end

    # Process each of the requirements of this dep in order. If this is a dry
    # run, check every one; otherwise, require success from all and fail fast.
    def run_requirements accessor, and_meet
      if and_meet
        requirements_for(accessor).all? {|r| run_requirement(r, and_meet) }
      else
        requirements_for(accessor).map {|r| run_requirement(r, and_meet) }.all?
      end
    end

    # Find the dep named in +requirement+, loading and running it as required,
    # and run it.
    #
    # Each dep recursively processes its own requirements. Hence, this is the
    # method that recurses down the dep tree.
    def run_requirement requirement, and_meet
      Base.sources.find_or_suggest requirement.name, :from => dep_source do |dep|
        dep.with(*requirement.args).process_as_requirement(and_meet, callstack, cache)
      end
    rescue SourceLoadError => e
      Babushka::Logging.log_exception(e)
    end

    # Defer to this dep's context to run the named block.
    def invoke block_name
      context.invoke(block_name)
    end

    # The list of requirements named in +list_name+ (either :requires or
    # :requires_when_unmet), as a list of DepRequirements, which represent
    # the name of the dep and the arguments to run it with.
    def requirements_for list_name
      context.send(list_name).map {|dep_or_requirement|
        if dep_or_requirement.is_a?(DepRequirement)
          dep_or_requirement
        else
          DepRequirement.new(dep_or_requirement, [])
        end
      }
    end

    def logging_name
      if Base.task.opt(:show_args) || Base.task.opt(:debug)
        "#{contextual_name}(#{args.values.map(&:description).join(', ')})"
      else
        contextual_name
      end
    end

    def log_exception_in_dep e
      Babushka::Logging.log_exception(e)
      advice = e.is_a?(DepDefinitionError) ? "Looks like a problem with '#{name}' - check" : "Check"
      log "#{advice} #{(e.backtrace.detect {|l| l[load_path.to_s] } || load_path).sub(/\:in [^:]+$/, '')}." unless load_path.nil?
    end

    def log_cached result, and_meet
      if result
        log "#{Logging::TICK_CHAR} #{name} (cached)".colorize('green')
      elsif !and_meet
        log "~ #{name} (cached)".colorize('blue')
      end
    end

    def suffixed?
      !opts[:template] && template != self.class.base_template
    end

    public

    def inspect
      "#<Dep:#{object_id} '#{dep_source.name}:#{name}'>"
    end
  end
end
