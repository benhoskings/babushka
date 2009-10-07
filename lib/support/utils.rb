alias :L :lambda

def host
  @host ||= Babushka::SystemSpec.for_system
end

def hostname
  shell 'hostname -f'
end

require 'etc'
def pathify str
  File.expand_path str.sub(/^\~\/|^\~$/) {|_| Etc.getpwuid(Process.euid).dir.end_with('/') }
end
