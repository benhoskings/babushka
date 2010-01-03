module Babushka
  class MetaDepDefiner

    attr_reader :opts, :definer_class, :runner_class

    def initialize name, opts, &block
      @opts = opts
      @definer_class = build_definer
      @runner_class = build_runner
    end

    def build_definer
      Class.new BaseDepDefiner
    end

    def build_runner
      Class.new BaseDepRunner
    end

  end
end
