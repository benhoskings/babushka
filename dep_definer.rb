require 'pkg_manager'

class DepDefiner
  def initialize name, &block
    @name = name
    @defines = {:requires => []}
    instance_eval &block if block_given?
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
      :met? => @defines[:met?] || default_met_block,
      :meet => @defines[:meet] || default_meet_block
    }
  end

  private

  def default_met_block
    L{
      log "met? { } not defined for #{name}, moving on."
      true
    }
  end

  def default_meet_block
    L{ log "meet { } not defined for #{name}; nothing to do." }
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
        install_packages
      }
    })
  end

  private

  def packages_present
    if pkg_or_default.is_a? Hash
      pkg_or_default.all? {|pkg_name, version| pkg_manager.has?(pkg_name, version) }
    else
      pkg_or_default.all? {|pkg_name| pkg_manager.has?(pkg_name) }
    end
  end

  def cmds_in_path
    provides_or_default.all? {|cmd_name|
      pkg_manager.cmd_in_path? cmd_name
    }
  end

  def install_packages
    pkg_manager.install! pkg_or_default
  end

  def pkg_manager
    PkgManager.for_system
  end

  def pkg_or_default
    if @pkg.nil?
      @name
    elsif @pkg.is_a? Hash
      @pkg[pkg_manager.manager_key]
    else
      [*@pkg]
    end
  end
  def provides_or_default
    @provides || [@name]
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
