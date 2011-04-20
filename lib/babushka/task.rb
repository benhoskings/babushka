module Babushka
  class Task
    include Singleton
    include PathHelpers

    attr_reader :base_opts, :run_opts, :vars, :persistent_log
    attr_accessor :cmdline, :reportable

    def initialize
      @vars = Vars.new
      @run_opts = default_run_opts
    end

    def process dep_names, with_vars = {}
      raise "A task is already running." if running?
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
          dep.process(:top_level => true).tap {|result|
            save_run_info_for dep, result
          }
        }.tap {|result|
          log "You can view #{opt(:debug) ? 'the' : 'a more detailed'} log at '#{log_path_for(dep)}'." unless result
          RunReporter.queue dep, result, reportable
          BugReporter.report dep if reportable
        }
      end
    end

    def task_info dep, result
      {
        :version => Babushka::VERSION,
        :run_at => Time.now,
        :system_info => Base.host.description,
        :dep_name => dep.name,
        :source_uri => dep.dep_source.uri,
        :result => result
      }
    end

    def cmdline
      @cmdline ||= Cmdline::Parser.for(ARGV)
    end

    def opts
      cmdline.opts.merge @run_opts
    end

    def opt name
      opts[name]
    end

    def running?
      @running
    end

    def callstack
      opts[:callstack]
    end

    def log_path_for dep
      log_prefix / dep.contextual_name
    end

    def var_path_for dep
      VarsPrefix.p / dep.contextual_name
    end

    private

    def log_dep dep
      log_prefix.mkdir
      log_path_for(dep).open('w') {|f|
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

    def default_run_opts
      {
        :callstack => []
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
