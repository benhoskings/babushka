module Babushka
  class Base
    Verb = Struct.new :name, :short, :long, :description, :opts, :args
    Opt = Struct.new :name, :short, :long, :description, :optional, :args
    Arg = Struct.new :name, :description, :optional, :multi, :example
    PassedVerb = Struct.new :def, :opts, :args
    PassedOpt = Struct.new :def, :args
    PassedArg = Struct.new :def, :value
  end
end
