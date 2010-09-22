module Babushka
  class Task
    include PathHelpers

    attr_reader :base_opts, :run_opts, :vars, :current_dep, :saved_vars, :persistent_log
    attr_accessor :verb, :reportable

    def initialize
      @vars = Hashish.hash
      @saved_vars = Hashish.hash
      @run_opts = default_run_opts
    end

    def process dep_spec
      load_previous_run_info_for dep_spec
      returning(log_dep(@current_dep = dep_spec) {
        returning Dep.process(dep_spec, :top_level => true) do |result|
          unless result.nil? # nil means the dep isn't defined
            save_run_info_for dep_spec, result
            log "You can view #{opt(:debug) ? 'the' : 'a more detailed'} log at '#{LogPrefix / dep_spec}'." unless result
            RunReporter.report Dep(dep_spec), result, reportable
          end
        end
      }) {
        BugReporter.report dep_spec if reportable
        @current_dep = nil
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

    def callstack
      opts[:callstack]
    end

    def log_path_for dep_name
      log_prefix / dep_name
    end

    def var_path_for dep_name
      VarsPrefix.p / dep_name
    end

    def sticky_var_path
      WorkingPrefix.p / 'sticky_vars'
    end

    private

    def log_dep dep_name
      FileUtils.mkdir_p log_prefix unless File.exists? log_prefix
      File.open(log_path_for(dep_name), 'w') {|f|
        @persistent_log = f
        returning(yield) { @persistent_log = nil }
      }
    end

    def log_prefix
      LogPrefix.p
    end

    require 'yaml'
    def load_previous_run_info_for dep_name
      load_var_log_for(var_path_for(dep_name)).each_pair {|var_name,var_data|
        @saved_vars[var_name].update var_data
      }
      load_var_log_for(sticky_var_path).each_pair {|var_name,var_data|
        debug "Updating sticky var #{var_name}: #{var_data.inspect}"
        @vars[var_name].update var_data
      }
    end

    def save_run_info_for dep_name, result
      save_var_log_for sticky_var_path, :vars => sticky_vars_for_save
      save_var_log_for var_path_for(dep_name), {
        :info => task_info(Dep(dep_name), result),
        :vars => vars_for_save
      }
    end


    private

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

    def task_info dep, result
      now = Time.now
      {
        :version => Babushka::VERSION,
        :date => now,
        :unix_date => now.to_i,
        :uname => `uname -a`,
        :dep_name => dep.name,
        :result => result
      }
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
