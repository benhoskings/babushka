module Babushka
  module UriHelpers

    def setup_source_uris
      deprecated! '2013-04-21', :method_name => "#setup_source_uris isn't required anymore and now has no effect, and so"
    end

    def uri_processor(method_name)
      L{|uri| URI.send(method_name, uri.respond_to?(:call) ? uri.call : uri.to_s) }
    end

    def process_sources &block
      uris = source.map(&uri_processor(:escape)).map(&uri_processor(:parse))
      extra_uris = extra_source.map(&uri_processor(:escape)).map(&uri_processor(:parse)) if respond_to?(:extra_source)

      extra_uris.each {|uri| Resource.extract(uri) } unless extra_uris.nil?
      uris.all? {|uri| Resource.extract(uri, &block) } unless uris.nil?
    end

    def handle_source uri, &block
      deprecated! '2013-04-21', :instead => 'Resource.extract(uri) { ... }'
      Resource.extract uri, &block
    end

  end
end
