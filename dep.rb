require 'dep_definer'

class Dep
  attr_reader :name

  def initialize name, block, definer_class = DepDefiner
    @name = name
    @vars = {}
    @payload = {
      :requires => [],
      :asks_for => []
    }.merge definer_class.new(name, &block).payload
    debug "\"#{name}\" depends on #{@payload[:requires].inspect}"
    Dep.register self
  end

  def self.deps
    @@deps
  end

  def self.register dep
    @@deps ||= {}
    raise "There is already a registered dep called '#{dep.name}'." unless @@deps[dep.name].nil?
    @@deps[dep.name] = dep
  end
  def self.for name
    @@deps ||= {}
    returning dep = @@deps[name] do |result|
      log"#{name.colorize 'grey'} #{"<- this dep isn't defined!".colorize('red')}" unless result
    end
  end

  def met?
    process :attempt_to_meet => false
  end
  def meet
    process :attempt_to_meet => !Cfg[:dry_run]
  end

  private

  def process opts = {}
    cached? ? cached_result : process_and_cache(opts)
  end

  def process_and_cache opts
    log name, :closing_status => (opts[:attempt_to_meet] ? true : :dry_run) do
      ask_for_vars and process_deps(opts) and process_self(opts)
    end
  end

  def ask_for_vars
    @payload[:asks_for].each {|key|
      log "#{key} for #{name}", :newline => false
      L{
        @vars[key] = read_from_prompt
        break unless @vars[key].blank?
        log "That was blank. #{key} for #{name}", :newline => false
        redo
      }.call
    }
  end

  def process_deps opts
    closure = L{|dep|
      dep = Dep(dep)
      dep.send :process, opts unless dep.nil?
    }
    if opts[:attempt_to_meet]
      @payload[:requires].all? &closure
    else
      @payload[:requires].each &closure
    end
  end

  def process_self opts
    if !(met_result = run_met_task(opts.merge(:initial => true)))
      if !opts[:attempt_to_meet]
        met_result
      else
        call_task(:meet) and run_met_task(opts)
      end
    elsif :fail == met_result
      log "fail lulz"
    else
      true
    end
  end

  def run_met_task opts
    returning cache_process(call_task(:met?)) do |result|
      if :fail == result
        log_extra "You'll have to fix '#{name}' manually."
      elsif !result && opts[:initial]
        log_extra "#{name} not already met."
      elsif result && !opts[:initial]
        log "#{name} met.".colorize('green')
      end
    end
  end

  def has_task? task_name
    !@payload[task_name].nil?
  end

  def call_task task_name
    (@payload[task_name] || default_task(task_name)).call
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
      log "#{name} (cached)".colorize('grey'), :as => (result ? :ok : :error)
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

  def inspect
    "#<Dep:#{object_id} '#{name}' { #{@payload[:requires].join(', ')} }>"
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
