require 'dep_definer'

class Dep
  attr_reader :name
  
  def initialize name, block, definer_class = DepDefiner
    @name = name
    @defines = definer_class.new(&block).payload
    [:requires, :met?, :meet].each {|item|
      raise "You need to specify '#{item}' in the dep \"#{name}\" definition." if @defines[item].nil?
    }
    # log "Dep #{name} depends on #{@defines[:requires].inspect}"
    Dep.register self
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
  
  def dep_task method_name
    @defines[:requires].all? {|requirement|
      dep = Dep(requirement)
      dep.send method_name unless dep.nil?
    }
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
        # begin
          dep_task(:meet) && (run_met_task || run_meet_task)
        # rescue Exception => e
        #   log "Tried to install #{@name}, and #{e.to_s} out of fucking nowhere."
        #   log e.backtrace.inspect
        #   false
        # end
      end
    end
  end
  
  def run_met_task
    unless @_cached_met.nil?
      log [name.colorize('grey'), "#{'un' unless @_cached_met}met".colorize(@_cached_met ? 'green' : 'red')].join(' ')
      @_cached_met
    else
      @_cached_met = returning @defines[:met?].call do |result|
        log "#{name} #{'not ' unless result}already met.".colorize(result ? 'green' : nil) unless result
      end
    end
  end
  
  def run_meet_task
    returning(@defines[:meet].call && @defines[:met?].call) do |result|
      log "#{name} #{"couldn't be " unless result}met.".colorize(result ? 'green' : 'red')
    end
  end
  
  def inspect
    "#<Dep:#{object_id} '#{name}' { #{@defines[:requires].join(', ')} }>"
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
