module Babushka
  class DepDefiner
    include ShellHelpers
    include DefinerHelpers
    include VersionList

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

    def run_in path_or_key
      asks_for path_or_key if path_or_key.is_a?(Symbol)
      payload[:run_in] = path_or_key
    end
    def set key, value
      @dep.set key, value
    end

    def var name, default_value = nil
      if @dep.vars.has_key? name.to_s
        @dep.vars[name.to_s]
      else
        @dep.ask_for_var name.to_s, default_value
      end
    end

    def method_missing method_name, *args, &block
      var method_name, args.first
    end

  end
end
