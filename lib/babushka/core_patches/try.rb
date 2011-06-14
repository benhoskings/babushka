# The implementation of #try as found in activesupport:
#   lib/active_support/core_ext/object/try.rb
#
# Try is just a nil-swallowing send, which means return nil when called on
# nil and just send like normal when called on any other object.

class Object
  alias_method :try, :__send__
end

class NilClass
  def try *args
    nil
  end
end
