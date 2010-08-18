alias :L :lambda

class Object
  def returning obj, &block
    yield obj
    obj
  end

  def in? first, *rest
    (first.is_a?(Array) ? first : [first].concat(rest)).include? self
  end

  def metaclass
    class << self; self end
  end

  def singleton
    Class.new self
  end

  def recursive_const_get name
    name.split('::').inject(Object) {|klass,name| klass.const_get name }
  end

  def blank?
    nil? || (respond_to?(:empty?) && empty?)
  end

  def tap &block
    returning(self) { yield self }
  end
  def tapp
    tap { puts "#{File.basename caller[4]}: #{self.inspect}" }
  end
  def taph
    tap { puts("#{File.basename caller[4]}: #{self.inspect}".gsub('&', '&amp;').gsub('<', '&lt;') + "<br />") }
  end
  require 'pp'
  def tappp
    tap { pp self }
  end
  def tap_log
    returning(self) { log_verbose self }
  end
end

unless Object.new.respond_to? :instance_exec
  # http://eigenclass.org/hiki/bounded+space+instance_exec
  class Object
    module InstanceExecHelper; end
    include InstanceExecHelper
    def instance_exec(*args, &block)
      begin
        old_critical, Thread.critical = Thread.critical, true
        n = 0
        n += 1 while respond_to?(mname="__instance_exec#{n}")
        InstanceExecHelper.module_eval{ define_method(mname, &block) }
      ensure
        Thread.critical = old_critical
      end
      begin
        ret = send(mname, *args)
      ensure
        InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
      end
      ret
    end
  end
end
