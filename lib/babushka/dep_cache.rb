module Babushka
  class DepCache

    def initialize
      @caches = {}
    end

    def read key, opts = {}, &block
      if @caches.has_key?(key)
        @caches[key].tap {|value|
          opts[:hit].call(value) if opts.has_key?(:hit)
        }
      else
        @caches[key] = block.call
      end
    end

  end
end
