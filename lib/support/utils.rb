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
def linux?; :linux == uname end
def osx?; :osx == uname end

def from_first_and_rest first, rest
  first.is_a?(Hash) ? first : [*first].concat(rest)
end
