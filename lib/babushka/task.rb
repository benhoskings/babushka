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
      cleanup_obsolete_data # TODO: remove after August '13 or so.
      dep_names.all? {|dep_name| process_dep(dep_name, with_args) }
    rescue SourceLoadError => e
      Babushka::Logging.log_exception(e)
    ensure
      clear
    end

    def process_dep dep_name, with_args
      Base.sources.find_or_suggest(dep_name) do |dep|
        @current_dep = dep
        log_dep(dep) {
          dep.with(task_args_for(dep, with_args)).process(!opt(:dry_run))
        }.tap {|result|
          @current_dep = nil
          log_stderr "You can view #{opt(:debug) ? 'the' : 'a more detailed'} log at '#{log_path_for(dep)}'." unless result
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

    def reopen_log!
      if @persistent_log
        old_log = @persistent_log
        @persistent_log = File.open(old_log.path, 'a')
        @persistent_log.sync = true
        old_log.flush
        old_log.close
      end
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

    def log_dep dep
      log_prefix.mkdir
      log_path_for(dep).open('w') {|f|
        f.sync = true
        @persistent_log = f

        # Note the current babushka & ruby versions at the top of the log.
        LogHelpers.debug(Base.runtime_info)

        yield
      }
    ensure
      @persistent_log = nil
    end

    def log_prefix
      Babushka::LOG_PREFIX.p
    end

    def cleanup_obsolete_data
      Babushka::VARS_PREFIX.p.rm if Babushka::VARS_PREFIX.p.exists?
      Babushka::REPORT_PREFIX.p.rm if Babushka::REPORT_PREFIX.p.exists?
    end

  end
end
