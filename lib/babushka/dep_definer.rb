module Babushka
  class DepDefiner
    include ShellHelpers
    include DefinerHelpers

    attr_reader :payload, :source

    def initialize dep
      @dep = dep
      @payload = {
        :requires => Hashish.array,
        :asks_for => []
      }
      @source = self.class.current_load_path
    end

    def process &block
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

    def self.accepts_hash_for method_name, payload_key = method_name
      define_method method_name do |first, *rest|
        val = from_first_and_rest(first, rest)
        if val.is_a? Array
          send method_name, :all => val
        else
          val.each_pair {|acc,val|
            (payload[payload_key] ||= Hashish.array)[acc].concat([*val]).uniq!
          }
        end
      end
      define_method "#{method_name}_for_system" do
        (payload[method_name][:all] + payload[method_name][uname]).uniq unless payload[method_name].nil?
      end
    end

    accepts_hash_for :requires

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

    def method_missing method_name, *args, &block
      if @dep.vars.has_key? method_name.to_s
        @dep.vars[method_name.to_s]
      else
        @dep.ask_for_var method_name.to_s, args.first
      end
    end

  end
end
