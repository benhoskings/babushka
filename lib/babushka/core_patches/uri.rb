require 'uri'
module URI
  module Escape
    alias_method :original_escape, :escape

    # Patch URI.escape to prevent multiple escapes, by unescaping the input
    # before escaping it.
    #
    # For example, URI.escape normally behaves like this:
    #   URI.escape "path with spaces"      #=> "path%20with%20spaces"
    #   URI.escape "/path%20with%20spaces" #=> "/path%2520with%2520spaces"
    #
    # This patched version behaves like this:
    #   URI.escape "/path with spaces"     #=> "/path%20with%20spaces"
    #   URI.escape "/path%20with%20spaces" #=> "/path%20with%20spaces"
    #
    # This is pretty cheeky, but as far as I can see it won't cause any
    # problems - I can't see any situation where a doubly-escaped entity is a
    # good thing.
    def escape str, unsafe = URI::UNSAFE
      URI.original_escape URI.unescape(str), unsafe
    end
  end
end
