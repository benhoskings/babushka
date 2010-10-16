module Babushka
  class Task
    include PathHelpers

    attr_reader :base_opts, :run_opts, :vars, :saved_vars, :persistent_log
    attr_accessor :verb, :reportable

    def initialize
      @vars = Hashish.hash
      @saved_vars = Hashish.hash
      @run_opts = default_run_opts
    end

    def process dep_names
      raise "A task is already running." if running?
      @running = true
      Base.in_thread { RunReporter.post_reports }
      dep_names.all? {|dep_name| process_dep dep_name }
    ensure
      @running = false
    end

    def process_dep dep_name
      Dep.find_or_suggest dep_name do |dep|
        returning run_dep(dep) do |result|
          log "You can view #{opt(:debug) ? 'the' : 'a more detailed'} log at '#{log_path_for(dep)}'." unless result
          RunReporter.queue dep, result, reportable
          BugReporter.report dep if reportable
        end
      end
    end

    def run_dep dep
      log_dep dep do
        load_previous_run_info_for dep
        returning dep.process(:top_level => true) do |result|
          save_run_info_for dep, result
        end
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

    def opts
      verb_opts.merge @run_opts
    end

    def verb_opts
      verb.nil? ? {} : @verb.opts.inject({}) {|hsh,opt| hsh[opt.def.name] = true; hsh }
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

    def sticky_var_path
      WorkingPrefix.p / 'sticky_vars'
    end

    private

    def log_dep dep
      log_prefix.mkdir
      log_path_for(dep).open('w') {|f|
        @persistent_log = f
        returning(yield) { @persistent_log = nil }
      }
    end

    def log_prefix
      LogPrefix.p
    end

    require 'yaml'
    def load_previous_run_info_for dep
      load_var_log_for(var_path_for(dep)).each_pair {|var_name,var_data|
        @saved_vars[var_name].update var_data
      }
      load_var_log_for(sticky_var_path).each_pair {|var_name,var_data|
        debug "Updating sticky var #{var_name}: #{var_data.inspect}"
        @vars[var_name].update var_data
      }
    end

    def save_run_info_for dep, result
      save_var_log_for sticky_var_path, :vars => sticky_vars_for_save
      save_var_log_for var_path_for(dep), {
        :info => task_info(dep, result),
        :vars => vars_for_save
      }
    end

    def default_run_opts
      {
        :callstack => []
      }
    end

    def load_var_log_for path
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
      in_dir File.dirname(var_path), :create => true do |path|
        debug "Saving #{var_path}"
        dump_yaml_to File.basename(var_path), data
      end
    end

    def dump_yaml_to filename, data
      File.open(filename, 'w') {|f| YAML.dump data, f }
    end

    def sticky_vars_for_save
      vars.reject {|var,data|
        !data[:sticky]
      }.map_values {|k,v|
        v.reject {|k,v| k != :value }
      }
    end

    def vars_for_save
      vars.dup.inject(saved_vars.dup) {|vars_to_save,(var,data)|
        vars_to_save[var].update vars[var]
        save_referenced_default_for(var, vars_to_save) if vars[var][:default].is_a?(Symbol)
        vars_to_save
      }.reject_r {|var,data|
        !data.class.in?([String, Symbol, Hash, Numeric, TrueClass, FalseClass]) ||
        var.to_s['password']
      }
    end

    def save_referenced_default_for var, vars_to_save
      vars_to_save[var][:values] ||= {}
      vars_to_save[var][:values][ # set the saved value of this var
        vars[vars[var][:default].to_s][:value] # for this var's current default reference
      ] = vars_to_save[var].delete(:value) # to the referenced var's value
    end

  end
end
