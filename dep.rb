require 'dep_definer'
require 'gem_helpers'

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
    @@deps[name]
  end
  
  def dep_task method_name
    @defines[:requires].all? {|requirement|
      if (dep = Dep(requirement)).nil?
        raise "dep '#{name}' requires '#{requirement}', which doesn't exist."
      else
        dep.send method_name
      end
    }
  end

  def met?
    @cached_met ||= dep_task(:met?) && run_met_task
  end
  
  def meet
    log name do
      # begin
        dep_task(:meet) && (met? || run_meet_task)
      # rescue Exception => e
      #   log "Tried to install #{@name}, and #{e.to_s} out of fucking nowhere."
      #   log e.backtrace.inspect
      #   false
      # end
    end
  end
  
  def run_met_task
    returning @defines[:met?].call do |result|
      log "#{name} #{'not ' unless result}already met.".colorize(result ? 'green' : nil)
    end
  end
  
  def run_meet_task
    returning @defines[:meet].call do |result|
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
