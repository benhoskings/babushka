alias :L :lambda

def host
  Babushka::Base.host
end

def hostname
  shell 'hostname -f'
end

require 'etc'
def pathify str
  File.expand_path str.sub(/^\~\/|^\~$/) {|_| Etc.getpwuid(Process.euid).dir.end_with('/') }
end
