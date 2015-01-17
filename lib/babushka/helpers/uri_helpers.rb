module Babushka
  module UriHelpers

    def setup_source_uris
      removed! :method_name => "#setup_source_uris isn't required anymore and now has no effect, and so"
    end

    def process_sources &block
      removed! :instead => 'sources.each {|uri| Resource.extract(uri) { ... } }'
    end

    def handle_source uri, &block
      removed! :instead => 'Resource.extract(uri) { ... }'
    end

  end
end
