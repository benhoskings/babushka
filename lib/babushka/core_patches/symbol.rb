unless :to_proc.respond_to? :to_proc
  class Symbol
    # Returns a Proc object which responds to a method whose name is this
    # symbol.
    #
    # This is a fallback implementation for older rubies that don't have
    # a built-in Symbol#to_proc.
    def to_proc
      L{|*args| args.shift.__send__ self, *args }
    end
  end
end
