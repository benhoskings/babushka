require 'pathname'

class Fancypath < Pathname
  module Helpers
    require 'etc'
    def to_fancypath
      Fancypath.new File.expand_path sub(/^\~\/|^\~$/) {|_| Etc.getpwuid(Process.euid).dir.end_with('/') }
    end
    alias :p :to_fancypath
  end

  # methods are chainable and do what you think they do

  alias_method :to_str, :to_s unless method_defined? :to_str

  alias_method :dir, :dirname
  alias_method :directory, :dirname

  alias_method :dir?, :directory?

  alias_method :expand, :expand_path
  alias_method :abs, :expand_path
  alias_method :absolute, :expand_path

  alias_method :exists?, :exist?
  alias_method :rename_to, :rename

  def == other
    if other.is_a? String
      to_s == other
    else
      super
    end
  end

  def length
    to_s.length
  end

  def join(path)
    super(path.to_s).p
  end

  alias_method :/, :join

  # make file
  def touch
    FileUtils.touch self.to_s
    self
  end

  def create_dir
    mkpath unless exist?
    self
  end

  alias_method :create, :create_dir

  def copy(dest)
    FileUtils.cp(self, dest)
    self
  end

  alias_method :cp, :copy

  # file or dir
  def remove
    directory? ? rmtree : delete if exist?
    self
  end
  alias_method :rm, :remove

  def readlink
    symlink? ? super.p : self
  end

  def mkdir
    require 'fileutils'
    FileUtils.mkdir_p self
    self
  end

  def glob expr, &block
    Dir.glob self / expr, &block
  end

  def write(contents, mode='wb')
    dirname.create
    open(mode) { |f| f.write contents }
    self
  end

  def append(contents)
    write(contents,'a+')
    self
  end

  def move(dest)
    self.rename(dest)
    dest.p
  end

  def tail(bytes)
    return self.read if self.size < bytes
    open('r') do |f|
      f.seek(-bytes, IO::SEEK_END)
      f.read
    end
  end

  alias_method :mv, :move

  def set_extension(ext)
    "#{without_extension}.#{ext}".p
  end

  alias_method :change_extension, :set_extension

  def without_extension
    to_s[/^ (.+?) (\. ([^\.]+))? $/x, 1].p
  end

  def has_extension?(ext)
    !!(self.to_s =~ /\.#{ext}$/)
  end

  def parent
    super.p
  end

  alias_method :all_children, :children

  def children
    super.reject { |c| c.basename.to_s =~ /^\./ }
  end

  # only takes sym atm
  def select(*args)
    return args.map { |arg| select(arg) }.flatten.uniq if args.size > 1

    case arg = args.first
    when Symbol
      Dir["#{self}/*.#{arg}"].map { |p| self.class.new(p) }
    when Regexp
      children.select { |child| child.to_s =~ arg }
    else
      Dir["#{self}/#{arg}"].map { |p| self.class.new(p) }
    end
  end
  
  def empty?
    directory? ? children.size == 0 : self.size == 0
  end
  
  def inspect
    super.sub('Pathname','Fancypath')
  end

  def to_fancypath
    self
  end

end

def Fancypath path
  Fancypath.new path
end
class Pathname
  include Fancypath::Helpers
end
class String
  include Fancypath::Helpers
end
