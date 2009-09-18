module Babushka
  LogPrefix = '~/.babushka/logs'.freeze
  VarsPrefix = '~/.babushka/vars'.freeze
  class Task

    attr_reader :base_opts, :run_opts, :vars, :saved_vars, :persistent_log

    def initialize
      @vars = Hashish.hash
      @saved_vars = Hashish.hash
      @base_opts = default_base_opts
      @run_opts = default_run_opts
    end

    def process dep_name
      load_previous_run_info_for dep_name
      log_dep dep_name do
        returning Dep.process dep_name do |result|
          save_run_info_for dep_name, result
        end
      end
    end

    def opts
      @base_opts.merge @run_opts
    end

    def debug?
      opts[:debug]
    end
    def quiet?
      opts[:quiet]
    end
    def dry_run?
      opts[:dry_run]
    end
    def callstack
      opts[:callstack]
    end

    def log_dep dep_name
      log_prefix = pathify LogPrefix
      FileUtils.mkdir_p log_prefix unless File.exists? log_prefix
      File.open(log_prefix / dep_name, 'w') {|f|
        @persistent_log = f
        returning(yield) { @persistent_log = nil }
      }
    end

    require 'yaml'
    def load_previous_run_info_for dep_name
      path = pathify(VarsPrefix / dep_name)
      unless File.exists? path
        log "No log to load for '#{path}'."
      else
        dep_log = YAML.load_file path
        unless dep_log.is_a?(Hash) && dep_log[:vars].is_a?(Hash)
          log_error "Ignoring corrupt var log at #{path}."
        else
          dep_log[:vars].each_pair {|var_name,var_data|
            @saved_vars[var_name].update var_data.tap{|obj| log "updating #{var_name}: #{saved_vars[var_name].inspect} -> #{obj.inspect}" }
          }
        end
      end
    end

    def save_run_info_for dep_name, result
      in_dir VarsPrefix, :create => true do |path|
        File.open(dep_name, 'w') {|f|
          YAML.dump({
            :info => task_info(dep_name, result),
            :vars => vars_for_save
          }, f)
        }
      end
    end

    private

    def default_base_opts
      {}
    end

    def default_run_opts
      {
        :callstack => []
      }
    end

    def task_info dep_name, result
      now = Time.now
      {
        :version => Babushka::VERSION,
        :date => now,
        :unix_date => now.to_i,
        :dep_name => dep_name,
        :result => result
      }
    end

    def vars_for_save
      vars.inject(saved_vars.dup) {|vars_to_save,(var,data)|
        vars_to_save[var].update vars[var]
        save_referenced_default_for(var, vars_to_save) if vars[var][:default].is_a?(Symbol)
        vars_to_save
      }.reject_r {|var,data|
        ![String, Symbol, Hash].include?(data.class) || var.to_s['password']
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
