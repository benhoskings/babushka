module Babushka
  Verb = Struct.new :name, :description, :opts, :args
  Opt = Struct.new :name, :short, :long, :description, :args
  Arg = Struct.new :name, :description, :optional, :multi
  PassedVerb = Struct.new :def, :opts, :args
  PassedOpt = Struct.new :def, :args 
  PassedArg = Struct.new :def, :value
end
