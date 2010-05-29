module Babushka
  class DepDefiner
    include Shell::Helpers
    include Prompt::Helpers
    include VersionList

    attr_reader :payload, :source_path

    delegate :name, :to => :dependency
    delegate :merge, :var, :define_var, :to => :runner

    def default_blocks
      self.class.default_blocks
    end
    def self.default_blocks
      merged_default_blocks_for self
    end
    def self.merged_default_blocks_for klass
      parent_values = klass == DepDefiner ? {} : merged_default_blocks_for(klass.superclass)
      parent_values.merge(default_blocks_for(klass))
    end
    def self.default_blocks_for klass
      (@@default_blocks ||= Hashish.hash)[klass]
    end

    def self.load_context opts, &block
      @@current_load_source = opts[:source]
      @@current_load_path = opts[:path]
      yield
    ensure
      @@current_load_source = @@current_load_path = nil
    end

    def self.define_dep name, in_opts, block, definer_class, runner_class
      if current_load_source.find name
        current_load_source.deps.skipped_count += 1
        current_load_source.find name
      else
        begin
          Dep.make name, current_load_source, current_load_path, in_opts, block, definer_class, runner_class
        rescue DepError => e
          log_error e.message
        end
      end
    end

    def initialize dep, &block
      @dep = dep
      @payload = {}
      @block = block
      @source_path = self.class.current_load_path.p unless self.class.current_load_path.nil?
    end

    def dependency
      @dep
    end

    def runner
      @dep.runner
    end

    def define_and_process
      process
      instance_eval &@block unless @block.nil?
    end

    def process
      true # overridden in subclassed definers
    end

    def self.current_load_source
      @@current_load_source ||= nil
      @@current_load_source || Base.sources.default
    end

    def self.current_load_path
      @@current_load_path ||= nil
    end

    def self.accepted_blocks
      default_blocks.keys
    end

    def self.load_deps_from path
      $stdout.flush
      previous_length, previous_skipped = Dep.pool.count, Dep.pool.skipped_count
      path.p.glob('**/*.rb').partition {|f|
        f.p.basename == 'templates.rb' or
        f.p.parent.basename == 'templates'
      }.flatten.each {|f|
        @@current_load_path = f
        begin
          require f
        rescue Exception => e
          log_error "#{e.backtrace.first}: #{e.message}"
          log "Check #{(e.backtrace.detect {|l| l[f] } || f).sub(/\:in [^:]+$/, '')}."
          debug e.backtrace * "\n"
        end
      }
      @@current_load_path = nil
      log_ok "Loaded #{Dep.pool.count - previous_length}#{" and skipped #{Dep.pool.skipped_count - previous_skipped}" unless Dep.pool.skipped_count == previous_skipped} deps from #{path}."
    end

    def self.accepts_block_for method_name, &default_block
      default_blocks_for(self)[method_name] = default_block
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

    def helper name, &block
      runner.metaclass.send :define_method, name do |*args|
        if block.arity == -1
          instance_exec *args, &block
        elsif block.arity != args.length
          raise ArgumentError, "wrong number of args to #{name} (#{args.length} for #{block.arity})"
        else
          instance_exec *args[0...(block.arity)], &block
        end
      end
    end

    def has_task? task_name
      payload[task_name] ||= {}
      !!specific_block_for(task_name)
    end

    def default_task task_name
      differentiator = host.differentiator_for payload[task_name].keys
      L{
        debug([
          "#{@dep.name} / #{task_name} not defined",
          "#{" for #{differentiator}" unless differentiator.nil?}",
          {
            :met? => ", moving on",
            :meet => " - nothing to do"
          }[task_name],
          "."
        ].join)
        true
      }
    end


    private

    def on platform, &block
      if platform.in? [*chooser]
        @current_platform = platform
        returning block.call do
          @current_platform = nil
        end
      end
    end

    def store_block_for method_name, args, block
      raise "#{method_name} only accepts args like :on => :linux (as well as a block arg)." unless args.empty? || args.first.is_a?(Hash)

      payload[method_name] ||= {}
      chosen_on = (args.first || {})[:on] || @current_platform || :all
      payload[method_name][chosen_on] = block
    end

    def block_for method_name
      specific_block_for(method_name) or default_task(method_name)
    end

    def specific_block_for method_name
      payload[method_name][(host.match_list & payload[method_name].keys).first] ||
      default_blocks[method_name]
    end

    def self.set_up_delegating_for method_name
      runner_class.send :delegate, method_name, :to => :definer
    end

    def self.runner_class
      Object.recursive_const_get name.to_s.sub('Definer', 'Runner')
    end

  end
end
