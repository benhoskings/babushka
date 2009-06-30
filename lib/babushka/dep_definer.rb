module Babushka
  class DepDefiner
    include ShellHelpers
    include DefinerHelpers

    attr_reader :payload, :source

    def initialize dep, &block
      @dep = dep
      @payload = {
        :requires => Hash.new {|hsh,k| hsh[k] = [] },
        :asks_for => []
      }
      @source = self.class.current_load_path
      default_init if respond_to? :default_init
      instance_eval &block if block_given?
    end

    def self.current_load_path
      @@current_load_path
    end

    def self.load_deps_from path
      $stdout.flush
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

    def requires first, *rest
      deps = from_first_and_rest(first, rest)
      if deps.is_a? Array
        requires :all => deps
      else
        deps.each_pair {|system,deps|
          payload[:requires][system].concat([*deps]).uniq!
        }
      end
    end
    def asks_for *keys
      payload[:asks_for].concat keys.map(&:to_s)
    end
    def run_in path_or_key
      asks_for path_or_key if path_or_key.is_a?(Symbol)
      payload[:run_in] = path_or_key
    end
    def set key, value
      @dep.set key, value
    end

    def met? &block
      payload[:met?] = block
    end
    def meet &block
      payload[:meet] = block
    end
    def before &block
      payload[:before] = block
    end
    def after &block
      payload[:after] = block
    end

    def self.attr_setter *names
      names.each {|name|
        define_method name do |first, *rest|
          instance_variable_set "@#{name}", from_first_and_rest(first, rest)
        end
      }
    end

    def method_missing method_name, *args, &block
      if @dep.vars.has_key? method_name.to_s
        @dep.vars[method_name.to_s]
      else
        @dep.ask_for_var method_name.to_s, args.first
      end
    end

  end

  class PkgDepDefiner < DepDefiner

    attr_setter :pkg, :provides

    private

    def default_init
      requires pkg_manager.manager_dep
      met? {
        if !applicable?
          log_ok "Not required on #{pkg_manager.manager_key}-based systems."
        else
          packages_present and cmds_in_path
        end
      }
      meet { install_packages }
    end

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
      present, missing = provides_or_default.partition {|cmd_name| cmd_dir(cmd_name) }
      good, bad = present.partition {|cmd_name| pkg_manager.cmd_in_path? cmd_name }

      log_ok "#{good.map {|i| "'#{i}'" }.to_list} run#{'s' if good.length == 1} from #{cmd_dir(good.first)}." unless good.empty?
      log_error "#{missing.map {|i| "'#{i}'" }.to_list} #{missing.length == 1 ? 'is' : 'are'} missing from your PATH." unless missing.empty?

      unless bad.empty?
        log_error "#{bad.map {|i| "'#{i}'" }.to_list} incorrectly run#{'s' if bad.length == 1} from #{cmd_dir(bad.first)}."
        log "You need to put #{pkg_manager.prefix} before #{cmd_dir(bad.first)} in your PATH."
      end

      missing.empty? and bad.empty?
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
      GemHelper
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
end
