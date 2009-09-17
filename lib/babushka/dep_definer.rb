module Babushka
  class DepDefiner
    include ShellHelpers
    include PromptHelpers
    include VersionList

    attr_reader :payload, :source_path

    class_inheritable_accessor :default_blocks

    delegate :name, :to => :dependency
    delegate :set, :merge, :var, :define_var, :to => :runner

    def initialize dep, &block
      @dep = dep
      @payload = {}
      @block = block
      @source_path = self.class.current_load_path
    end

    def dependency
      @dep
    end

    def runner
      @dep.runner
    end

    def process
      instance_eval &@block unless @block.nil?
    end

    def self.current_load_path
      @@current_load_path ||= nil
    end

    def self.accepted_blocks
      default_blocks.keys
    end

    def self.load_deps_from path
      $stdout.flush
      previous_length = Dep.deps.length
      Dir.glob(pathify(path) / '**/*.rb').each {|f|
        @@current_load_path = f
        begin
          require f
          @@current_load_path = nil
        rescue Exception => e
          log_error "#{e.backtrace.first}: #{e.message}"
          log "Check #{(e.backtrace.detect {|l| l[f] } || f).sub(/\:in [^:]+$/, '')}."
          return nil
        end
      }
      log_ok "Loaded #{Dep.deps.length - previous_length} deps from #{path}."
    end

    def self.accepts_block_for method_name, &default_block
      (self.default_blocks ||= {})[method_name] = default_block
      class_eval %Q{
        def #{method_name} *args, &block
          payload[#{method_name.inspect}] ||= {}
          if block.nil?
            block_for #{method_name.inspect}
          else
            store_block_for #{method_name.inspect}, args, block
          end
        end
      }
      set_up_delegating_for method_name
    end

    def default_task task_name
      L{
        send({:met? => :log_extra, :meet => :log_extra}[task_name] || :debug, [
          "#{@dep.name} / #{task_name} not defined",
          "#{" for #{uname_str}" unless (@dep.send(:payload)[task_name] || {})[:all].nil?}",
          {
            :met => ", moving on",
            :meet => " - nothing to do"
          }[task_name],
          "."
        ].join)
        true
      }
    end


    private

    def store_block_for method_name, args, block
      opts = {:on => :all}.merge(args.first || {})
      payload[method_name][opts[:on]] = block
    end

    def block_for method_name
      payload[method_name][uname] || payload[method_name][:all] || (self.class.default_blocks || {})[method_name]
    end

    def self.set_up_delegating_for method_name
      runner_class.send :delegate, method_name, :to => :definer
    end

    def self.runner_class
      Object.recursive_const_get name.to_s.sub('Definer', 'Runner')
    end

  end
end
