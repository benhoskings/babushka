require 'dep_definer'

class Dep
  attr_reader :name

  def initialize name, block, definer_class = DepDefiner
    @name = name
    @vars, @opts = {}, {}
    @definer = definer_class.new self, &block
    debug "\"#{name}\" depends on #{payload[:requires].inspect}"
    Dep.register self
  end

  def self.deps
    @@deps ||= {}
  end

  def self.register dep
    raise "There is already a registered dep called '#{dep.name}'." unless deps[dep.name].nil?
    deps[dep.name] = dep
  end
  def self.for name
    returning dep = deps[name] do |result|
      log"#{name.colorize 'grey'} #{"<- this dep isn't defined!".colorize('red')}" unless result
    end
  end

  def met? opts = {}
    process opts.merge default_run_opts.merge :attempt_to_meet => false
  end
  def meet opts = {}
    process opts.merge default_run_opts.merge :attempt_to_meet => !Cfg[:dry_run]
  end

  def vars
    (opts[:vars] || {}).merge @vars
  end
  def opts
    @opts.merge @run_opts || {}
  end


  private

  def process run_opts
    @run_opts = run_opts
    cached? ? cached_result : process_and_cache
  end

  def process_and_cache
    log name, :closing_status => (opts[:attempt_to_meet] ? true : :dry_run) do
      if opts[:callstack].include? self
        log_error "Oh crap, endless loop! (#{opts[:callstack].push(self).drop_while {|dep| dep != self }.map(&:name).join(' -> ')})"
      else
        opts[:callstack].push self
        returning ask_for_vars && process_in_dir do
          opts[:callstack].pop
        end
      end
    end
  end

  def ask_for_vars
    payload[:asks_for].reject {|key|
      vars[key]
    }.each {|key|
      @vars[key] = if [payload[:run_in]].include? key # TODO this should be elsewhere
        read_path_from_prompt "#{key.to_s.gsub('_', ' ')} for #{name}"
      else
        read_value_from_prompt "#{key.to_s.gsub('_', ' ')} for #{name}"
      end
    }
  end

  def process_in_dir
    path = payload[:run_in].is_a?(Symbol) ? vars[payload[:run_in]] : payload[:run_in]
    in_dir path do
      process_deps and process_self
    end
  end

  def process_deps
    closure = L{|dep|
      dep = Dep(dep)
      dep.send :process, opts.merge(:vars => vars) unless dep.nil?
    }
    if opts[:attempt_to_meet]
      payload[:requires].all? &closure
    else
      payload[:requires].each &closure
    end
  end

  def process_self
    if !(met_result = run_met_task(:initial => true))
      if !opts[:attempt_to_meet]
        met_result
      else
        call_task(:meet) and run_met_task
      end
    elsif :fail == met_result
      log "fail lulz"
    else
      true
    end
  end

  def run_met_task task_opts = {}
    returning cache_process(call_task(:met?)) do |result|
      if :fail == result
        log_extra "You'll have to fix '#{name}' manually."
      elsif !result && task_opts[:initial]
        log_extra "#{name} not already met."
      elsif result && !task_opts[:initial]
        log "#{name} met.".colorize('green')
      end
    end
  end

  def has_task? task_name
    !payload[task_name].nil?
  end

  def call_task task_name
    (payload[task_name] || default_task(task_name)).call
  end

  def default_task task_name
    {
      :met? => L{
        log_extra "#{name} / met? not defined, moving on."
        true
      },
      :meet => L{ log_extra "#{name} / meet not defined; nothing to do." }
    }[task_name]
  end

  def cached_result
    returning cached_process do |result|
      log_result "#{name} (cached)", :result => result
    end
  end
  def cached?
    instance_variable_defined? :@_cached_process
  end
  def cached_process
    @_cached_process
  end
  def cache_process value
    @_cached_process = value
  end

  def default_run_opts
    {
      :callstack => []
    }
  end

  def payload
    @definer.payload
  end

  def inspect
    "#<Dep:#{object_id} '#{name}' { #{payload[:requires].join(', ')} }>"
  end
end

def Dep name
  Dep.for name
end

def dep name, &block
  Dep.new name, block
end
def pkg_dep name, &block
  Dep.new name, block, PkgDepDefiner
end
def gem_dep name, &block
  Dep.new name, block, GemDepDefiner
end

def ext_dep name, &block
  Dep.new name, block, ExtDepDefiner
end
