require 'uri'
module URI
  module Escape
    alias_method :original_escape, :escape
    def escape str, unsafe = URI::UNSAFE
      URI.original_escape URI.unescape(str), unsafe
    end
  end
end
