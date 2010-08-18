unless :to_proc.respond_to? :to_proc
  class Symbol
    def to_proc
      L{|*args| args.shift.__send__ self, *args }
    end
  end
end
