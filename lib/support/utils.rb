alias :L :lambda

def host
  Babushka::Base.host
end

def hostname
  shell 'hostname -f'
end
