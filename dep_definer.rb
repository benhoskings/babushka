require 'pkg_manager'

class DepDefiner
  attr_reader :payload, :source

  def initialize dep, &block
    @dep = dep
    @payload = {
      :requires => [],
      :asks_for => []
    }
    @source = self.class.current_load_path
    instance_eval &block if block_given?
  end

  def self.current_load_path
    @@current_load_path
  end

  def self.load_deps_from path
    previous_count = Dep.deps.count
    returning(Dir.glob(File.expand_path(path) / '/**/*.rb').all? {|f|
      @@current_load_path = f
      returning require f do
        @@current_load_path = nil
      end
    }) do |result|
      log "Loaded #{Dep.deps.count - previous_count} dependencies from #{path}."
    end
  end

  def requires *deps
    payload[:requires] = deps
  end
  def asks_for *keys
    payload[:asks_for].concat keys
  end
  def run_in path_or_key
    asks_for path_or_key if path_or_key.is_a?(Symbol)
    payload[:run_in] = path_or_key
  end
  def met? &block
    payload[:met?] = block
  end
  def meet &block
    payload[:meet] = block
  end

  def self.attr_setter *names
    names.each {|name|
      define_method name do |obj|
        instance_variable_set "@#{name}", obj
      end
    }
  end

  def method_missing method_name, *args, &block
    if @dep.vars.has_key? method_name
      @dep.vars[method_name]
    else
      super
    end
  end

end

class PkgDepDefiner < DepDefiner

  attr_setter :pkg, :provides

  def payload
    super.merge({
      :requires => pkg_manager.manager_dep,
      :met? => L{
        if !applicable?
          log_ok "Not required on #{pkg_manager.manager_key}-based systems."
        else
          packages_present and cmds_in_path
        end
      },
      :meet => L{
        install_packages
      }
    })
  end

  private

  def applicable?
    !(@pkg.is_a?(Hash) && @pkg[pkg_manager.manager_key].blank?)
  end

  def packages_present
    if pkg_or_default.is_a? Hash
      pkg_or_default.all? {|pkg_name, version| pkg_manager.has?(pkg_name, version) }
    else
      pkg_or_default.all? {|pkg_name| pkg_manager.has?(pkg_name) }
    end
  end

  def cmds_in_path
    good, bad = provides_or_default.partition {|cmd_name|
      pkg_manager.cmd_in_path? cmd_name
    }

    log_ok "#{good.map {|i| "'#{i}'" }.to_list} run#{'s' if good.length == 1} from #{cmd_dir(good.first)}." unless good.empty?

    unless bad.empty?
      log_error "#{bad.map {|i| "'#{i}'" }.to_list} incorrectly run#{'s' if bad.length == 1} from #{cmd_dir(bad.first)}."
      log "You need to put #{pkg_manager.prefix} before #{cmd_dir(bad.first)} in your PATH."
    end

    bad.empty?
  end

  def install_packages
    pkg_manager.install! pkg_or_default
  end

  def pkg_manager
    PkgManager.for_system
  end

  def pkg_or_default
    if @pkg.nil?
      @dep.name
    elsif @pkg.is_a? Hash
      @pkg[pkg_manager.manager_key] || []
    else
      [*@pkg]
    end
  end
  def provides_or_default
    @provides || [@dep.name]
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

class ExtDepDefiner < DepDefiner

  def if_missing *cmds, &block
    @cmds, @block = cmds, block
    payload[:met?] = met_block
  end

  private

  def met_block
    L{
      returning cmds_present? do |result|
        @block.call unless result
      end
    }
  end

  def cmds_present?
    (@cmds || []).all? {|cmd| which cmd }
  end

end
