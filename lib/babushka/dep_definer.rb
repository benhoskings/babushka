module Babushka
  class DepDefiner
    include ShellHelpers
    include DefinerHelpers

    attr_reader :payload, :source

    def initialize dep, &block
      @dep = dep
      @payload = {}
      @block = block
      @source = self.class.current_load_path
    end

    def name
      @dep.name
    end

    def process
      instance_eval &@block unless @block.nil?
    end

    def self.current_load_path
      @@current_load_path ||= nil
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

    def self.accepts_hash_for method_name, default = nil
      define_method method_name do |*args|
        if args.blank?
          hash_for method_name, default
        else
          store_hash_for method_name, args
        end
      end
    end

    def store_hash_for method_name, args
      payload[method_name] = Hashish.array
      (
        args.first.is_a?(Hash) ? args.first : {:all => args.first}
      ).each_pair {|k,v|
        payload[method_name][k].concat([*v]).uniq!
      }
    end

    def hash_for method_name, default
      if payload[method_name].nil?
        default_value = default.is_a?(Symbol) ? send(default) : default
        [*default_value]
      else
        (payload[method_name][:all] + payload[method_name][uname]).uniq
      end
    end

    def self.accepts_block_for method_name
      (@@accepted_blocks ||= []).push method_name
      define_method method_name do |*args, &block|
        if block.nil?
          block_for method_name
        else
          store_block_for method_name, args, block
        end
      end
    end

    def store_block_for method_name, args, block
      opts = {:on => :all}.merge(args.first || {})
      (payload[method_name] = {})[opts[:on]] = block
    end

    def block_for method_name
      payload[method_name][uname] || payload[method_name][:all] unless payload[method_name].nil?
    end

    def self.accepted_blocks
      @@accepted_blocks
    end

    accepts_hash_for :requires, Hashish.array
    accepts_hash_for :asks_for, Hashish.array
    accepts_block_for :setup
    accepts_block_for :met?
    accepts_block_for :meet
    accepts_block_for :before
    accepts_block_for :after

    def run_in path_or_key
      asks_for path_or_key if path_or_key.is_a?(Symbol)
      payload[:run_in] = path_or_key
    end
    def set key, value
      @dep.set key, value
    end

    def method_missing method_name, *args, &block
      if @dep.vars.has_key? method_name.to_s
        @dep.vars[method_name.to_s]
      else
        @dep.ask_for_var method_name.to_s, args.first
      end
    end

  end
end
