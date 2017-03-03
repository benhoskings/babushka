module Babushka
  class Task
    include LogHelpers
    include PathHelpers
    include ShellHelpers

    attr_reader :cmd, :persistent_log, :current_dep

    def initialize
      clear
    end

    def clear
      @cmd = nil
      @running = false
    end

    def process dep_names, with_args, cmd
      raise "A task is already running." if running?
      @cmd = cmd
      @running = true
      dep_names.all? {|dep_name| process_dep(dep_name, with_args) }
    rescue SourceLoadError => e
      Babushka::Logging.log_exception(e)
    ensure
      clear
    end

    def process_dep dep_name, with_args
      Base.sources.find_or_suggest(dep_name) do |dep|
        @current_dep = dep
        with_logging {
          dep.with(task_args_for(dep, with_args)).process(!opt(:dry_run))
        }.tap {
          @current_dep = nil
        }
      end
    end

    def opt name
      cmd.opts[name] unless cmd.nil?
    end

    def running?
      @running
    end

    def log_path_for dep
      log_prefix / dep.contextual_name
    end

    def open_log! mode = 'a'
      log_prefix.mkdir
      @persistent_log.close unless @persistent_log.nil? # If the log was already open, close it.
      @persistent_log = log_path_for(current_dep).open(mode).tap {|f| f.sync = true }
    end

    private

    def task_args_for dep, with_args
      with_args.keys.inject({}) {|hsh,k|
        # The string arg names are sanitized in the 'meet' cmdline handler.
        hsh[k.to_sym] = with_args[k]; hsh
      }.tap {|arg_hash|
        if (unexpected = arg_hash.keys - dep.params).any?
          log_warn "Ignoring unexpected argument#{'s' if unexpected.length > 1} #{unexpected.map(&:to_s).map(&:inspect).to_list}, which the dep '#{dep.name}' would reject."
          unexpected.each {|key| arg_hash.delete(key) }
        end
      }
    end

    def with_logging &blk
      open_log!('w')

      # Note the current babushka & ruby versions at the top of the log.
      LogHelpers.debug(Base.runtime_info)

      yield.tap {|result|
        log_stderr "You can view #{opt(:debug) ? 'the' : 'a more detailed'} log at '#{log_path_for(current_dep)}'." unless result
      }
    end

    def log_prefix
      Babushka::LOG_PREFIX.p
    end

  end
end
