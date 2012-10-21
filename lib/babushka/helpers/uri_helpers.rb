module Babushka
  module UriHelpers

    def setup_source_uris
      parse_uris
      requires_when_unmet(@uris.map(&:scheme).uniq & %w[ git ])
    end

    def parse_uris
      @uris = source.map(&uri_processor(:escape)).map(&uri_processor(:parse))
      @extra_uris = extra_source.map(&uri_processor(:escape)).map(&uri_processor(:parse)) if respond_to?(:extra_source)
    end

    def uri_processor(method_name)
      L{|uri| URI.send(method_name, uri.respond_to?(:call) ? uri.call : uri.to_s) }
    end

    def process_sources &block
      @extra_uris.each {|uri| handle_source uri } unless @extra_uris.nil?
      @uris.all? {|uri| handle_source uri, &block } unless @uris.nil?
    end

    def handle_source uri, &block
      uri = uri_processor(:parse).call(uri) unless uri.is_a?(URI)
      if uri.scheme == 'git'
        git uri, &block
      else # Pass any other protocol to `curl`.
        Resource.extract uri, &block
      end
    end

  end
end
