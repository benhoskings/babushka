# The implementation of #try as found in activesupport:
#   lib/active_support/core_ext/object/try.rb
#
# Try is just a nil-swallowing send, which means return nil when called on
# nil and just send like normal when called on any other object.

class Object
  def try(*args)
    Babushka::LogHelpers.deprecated! '2017-09-01'
    __send__(*args)
  end
end

class NilClass
  def try *args
    Babushka::LogHelpers.deprecated! '2017-09-01'
    nil
  end
end
