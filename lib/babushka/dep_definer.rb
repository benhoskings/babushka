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

    def self.accepts_hash_for method_name, default = {}
      (@@default_hash_payload ||= {})[method_name] = default
      define_method method_name do |first, *rest|
        payload[method_name] ||= @@default_hash_payload[method_name].dup
        if (val = from_first_and_rest(first, rest)).is_a? Array
          send method_name, :all => val
        else
          val.each_pair {|acc,val|
            payload[method_name][acc].concat([*val]).uniq!
          }
        end
      end
      define_method "#{method_name}_for_system" do
        if payload[method_name].nil?
          @@default_hash_payload[method_name]
        else
          (payload[method_name][:all] + payload[method_name][uname]).uniq
        end
      end
    end

    def self.accepts_block_for method_name, default = {}
      (@@default_block_payload ||= {})[method_name] = default
      define_method method_name do |*args, &block|
        payload[method_name] ||= @@default_block_payload[method_name].dup
        if (opts = args.first).nil?
          payload[method_name][:all] = block
        elsif !opts.is_a?(Hash)
          raise "The only argument #{method_name} accepts is a Hash of options."
        else
          payload[method_name][opts[:on] || :all] = block
        end
      end
      define_method "#{method_name}_for_system" do
        payload[method_name][uname] || payload[method_name][:all] unless payload[method_name].nil?
      end
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
