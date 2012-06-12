module Babushka
  class Task
    include Singleton
    include LogHelpers
    include PathHelpers
    include ShellHelpers

    attr_reader :opts, :vars, :caches, :persistent_log
    attr_accessor :reportable

    def initialize
      @opts = Base.cmdline.opts.dup
      @running = false
    end

    def process dep_names, with_vars
      raise "A task is already running." if running?
      @vars = Vars.new
      @running = true
      Base.in_thread { RunReporter.post_reports }
      dep_names.all? {|dep_name| process_dep dep_name, with_vars }
    ensure
      @running = false
    end

    def process_dep dep_name, with_vars
      Dep.find_or_suggest dep_name do |dep|
        log_dep(dep) {
          load_run_info_for dep, with_vars
          dep.with(task_args_for(dep, with_vars)).process.tap {|result|
            save_run_info_for dep, result
          }
        }.tap {|result|
          log_stderr "You can view #{opt(:debug) ? 'the' : 'a more detailed'} log at '#{log_path_for(dep)}'." unless result
          RunReporter.queue dep, result, reportable
          BugReporter.report dep if reportable
        }
      end
    end

    def cache &block
      was_caching, @caching, @caches = @caching, true, {}
      block.call
    ensure
      @caching = was_caching
    end

    def cached key, opts = {}, &block
      if !@caching
        block.call
      elsif @caches.has_key?(key)
        @caches[key].tap {|value|
          opts[:hit].call(value) if opts.has_key?(:hit)
        }
      else
        @caches[key] = block.call
      end
    end

    def task_info dep, result
      {
        :version => Base.ref,
        :run_at => Time.now,
        :system_info => Babushka.host.description,
        :dep_name => dep.name,
        :source_uri => dep.dep_source.uri,
        :result => result
      }
    end

    def opt name
      opts[name]
    end

    def running?
      @running
    end

    def callstack
      @callstack ||= []
    end

    def log_path_for dep
      log_prefix / dep.contextual_name
    end

    def var_path_for dep
      VarsPrefix.p / dep.contextual_name
    end

    private

    def task_args_for dep, with_vars
      with_vars.keys.inject({}) {|hsh,k|
        # The string arg names are sanitized in the 'meet' cmdline handler.
        hsh[k.to_sym] = with_vars[k]; hsh
      }.tap {|with_args|
        if (unexpected = with_args.keys - dep.params).any?
          log_warn "Ignoring unexpected argument#{'s' if unexpected.length > 1} #{unexpected.map(&:to_s).map(&:inspect).to_list}, which the dep '#{dep.name}' would reject."
          unexpected.each {|key| with_args.delete(key) }
        end
      }
    end

    def log_dep dep
      log_prefix.mkdir
      log_path_for(dep).open('w') {|f|
        f.sync = true
        @persistent_log = f
        yield.tap { @persistent_log = nil }
      }
    end

    def log_prefix
      LogPrefix.p
    end

    def load_run_info_for dep, with_vars
      load_var_log_for(var_path_for(dep)).each_pair {|var_name,var_data|
        vars.saved_vars[var_name].update var_data
      }
      with_vars.each_pair {|var_name,var_value|
        vars.vars[var_name].update :value => var_value
      }
    end

    def save_run_info_for dep, result
      save_var_log_for var_path_for(dep), {
        :info => task_info(dep, result),
        :vars => vars.for_save
      }
    end

    def load_var_log_for path
      require 'yaml'
      unless File.exists? path
        debug "No log to load for '#{path}'."
      else
        dep_log = YAML.load_file path
        unless dep_log.is_a?(Hash) && dep_log[:vars].is_a?(Hash)
          log_error "Ignoring corrupt var log at #{path}."
        else
          dep_log[:vars]
        end
      end || {}
    end

    def save_var_log_for var_path, data
      cd File.dirname(var_path), :create => true do |path|
        debug "Saving #{var_path}"
        dump_yaml_to File.basename(var_path), data
      end
    end

    def dump_yaml_to filename, data
      require 'yaml'
      File.open(filename, 'w') {|f| YAML.dump data, f }
    end

  end
end
