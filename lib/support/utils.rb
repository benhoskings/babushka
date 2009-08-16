alias :L :lambda

def uname
  {
    'Linux' => :linux,
    'Darwin' => :osx
  }[`uname -s`.chomp]
end
def uname_str
  {
    :osx => "OS X",
    :linux => "Linux"
  }[uname]
end
def system_version
  if osx?
    shell('sw_vers').val_for('ProductVersion')
  end
end
def system_release
  if osx?
    system_version.match(/\d+\.\d+/).to_s
  end
end
def system_name
  if osx?
    {
      '10.3' => 'Panther',
      '10.4' => 'Tiger',
      '10.5' => 'Leopard'
    }[system_release]
  end
end
def linux?; :linux == uname end
def osx?; :osx == uname end

require 'etc'
def pathify str
  File.expand_path str.sub(/^\~\/|^\~$/) {|_| Etc.getpwuid(Process.euid).dir.end_with('/') }
end
