require 'pkg_manager'

class DepDefiner
  def initialize &block
    @defines = {:requires => []}
    instance_eval &block
  end
  def requires *deps
    @defines[:requires] = deps
  end
  def met? &block
    @defines[:met?] = block
  end
  def meet &block
    @defines[:meet] = block
  end

  # def self.block_writer name
  #   define_method name do |&block|
  #     instance_variable_set name, block
  #   end
  # end
  def self.attr_setter *names
    names.each {|name|
      define_method name do |obj|
        instance_variable_set "@#{name}", obj
      end
    }
  end

  def payload
    {
      :requires => @defines[:requires],
      :met? => @defines[:met?],
      :meet => @defines[:meet]
    }
  end
end

class PkgDepDefiner < DepDefiner

  attr_setter :pkg, :provides

  def payload
    super.merge({
      :met? => lambda {
        @pkg[:macports].all? {|pkg_name| pkg_manager.has?(pkg_name) } &&
        @provides.all? {|cmd_name|
          pkg_manager.cmd_in_path? cmd_name
        }
      },
      :meet => lambda {
        'lol'
      }
    })
  end

end
