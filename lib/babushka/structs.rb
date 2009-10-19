module Babushka
  Verb = Struct.new 'Verb', :name, :description, :opts
  Opt = Struct.new 'Opt', :name, :short, :long, :description, :args
  Arg = Struct.new 'Arg', :name, :description, :optional
end
