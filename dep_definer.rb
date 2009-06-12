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
        packages_present && cmds_in_path
      },
      :meet => lambda {
        'lol'
      }
    })
  end

  private

  def packages_present
    if @pkg[pkg_manager.manager_key].is_a? Hash
      @pkg[pkg_manager.manager_key].all? {|pkg_name, version| pkg_manager.has?(pkg_name, version) }
    else
      @pkg[pkg_manager.manager_key].all? {|pkg_name| pkg_manager.has?(pkg_name) }
    end
  end

  def cmds_in_path
    (@provides || []).all? {|cmd_name|
      pkg_manager.cmd_in_path? cmd_name
    }
  end

  def pkg_manager
    PkgManager.for_system
  end
end

class GemDepDefiner < PkgDepDefiner

  def pkg obj
    @pkg = {:gem => obj}
  end

  private

  def pkg_manager
    GemHelper.new
  end
end
