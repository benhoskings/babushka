alias :L :lambda

def hostname
  shell 'hostname -f'
end
