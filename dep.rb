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
    debug "Dep #{name} depends on #{@payload[:requires].inspect}"
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
      log(name, :closing_status => true) { log_error "dep not defined!" } unless result
    end
  end

  def met?
    unless @_cached_met.nil?
      log "#{name} cached for met? (#{@_cached_met})."
      @_cached_met
    else
      dep_task(:met?) && run_met_task
    end
  end

  def meet
    unless @_cached_met.nil?
      log [name.colorize('grey'), "#{'un' unless @_cached_met}met".colorize(@_cached_met ? 'green' : 'red')].join(' ')
      @_cached_met
    else
      log name, :closing_status => true do
        ask_for_vars && dep_task(:meet) && (run_met_task || run_meet_task)
      end
    end
  end


  private

  def dep_task method_name
    @payload[:requires].all? {|requirement|
      dep = Dep(requirement)
      dep.send method_name unless dep.nil?
    }
  end

  def run_met_task
    unless @_cached_met.nil?
      log [name.colorize('grey'), "#{'un' unless @_cached_met}met".colorize(@_cached_met ? 'green' : 'red')].join(' ')
      @_cached_met
    else
      @_cached_met = returning call_task(:met?) do |result|
        log "#{name} #{'not ' unless result}already met.".colorize(result ? 'green' : nil) if result.nil?
      end
    end
  end

  def run_meet_task
    if @_cached_met == false
      log "You'll have to fix this manually."
    else
      returning(@payload[:meet].call && call_task(:met?)) do |result|
        log "#{name} #{"couldn't be " unless result}met.".colorize(result ? 'green' : 'red')
      end
    end
  end

  def ask_for_vars
    @payload[:asks_for].each {|key|
      log "#{key} for #{name}? ", :newline => false
      L{
        @vars[key] = $stdin.gets.chomp
        break unless @vars[key].blank?
        log "That was blank. #{key} for #{name}? ", :newline => false
        redo
      }.call
    }
  end

  def call_task task_name
    (@payload[task_name] || default_task(task_name)).call
  end

  def default_task task_name
    {
      :met? => L{
        log_verbose "met? { } not defined for #{name}, moving on."
        true
      },
      :meet => L{ log_verbose "meet { } not defined for #{name}; nothing to do." }
    }[task_name]
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
