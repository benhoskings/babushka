require 'pathname'

class Fancypath < Pathname
  module Helpers
    require 'etc'
    def to_fancypath
      Fancypath.new to_tilde_expanded_path
    end
    def to_expanded_fancypath
      Fancypath.new File.expand_path(to_tilde_expanded_path)
    end
    def to_tilde_expanded_path
      sub(/^\~\/|^\~$/) {|_| Etc.getpwuid(Process.euid).dir.end_with('/') }
    end
    alias :p :to_expanded_fancypath
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
    path_str = path.to_s
    super(path_str[0..0] == '/' ? path_str[1..-1] : path_str).p
  end

  alias_method :/, :join

  # This method returns true if the path is writable (i.e. and already
  # exists), or if the current user would be able to create it (i.e. if
  # its closest existing parent is writable).
  def hypothetically_writable?
    writable? || (!exists? && !root? && parent.hypothetically_writable?)
  end

  # make file
  def touch
    `touch '#{self}'`
    self
  end

  def create_dir
    mkpath unless exist?
    self
  end

  alias_method :create, :create_dir

  def copy(dest)
    `cp -pPR '#{self}' '#{dest}'`
    self
  end

  alias_method :cp, :copy

  # file or dir
  def remove
    directory? ? rmtree : delete if exist?
    self
  end
  alias_method :rm, :remove

  def read
    super.chomp if exists?
  end

  def grep *args
    if exists?
      matches = read.split("\n").grep(*args)
      matches unless matches.empty?
    end
  end

  def yaml
    require 'yaml'
    YAML.load_file self
  end

  def readlink
    if !symlink?
      self
    elsif
      target = super
      target.absolute? ? target : (dir / target)
    end
  end

  def mkdir
    `mkdir -p '#{self}'`
    self
  end

  def glob expr = nil, flags = File::FNM_CASEFOLD, &block
    Dir.glob((expr.nil? ? self : (self / expr)).to_s, flags, &block)
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

  def owner
    Etc.getpwuid(File.stat(to_s).uid).name
  end

  def group
    Etc.getgrgid(File.stat(to_s).gid).name
  end

  def inspect
    super.sub('Pathname','Fancypath')
  end

  def to_fancypath
    self
  end

end

class Pathname
  include Fancypath::Helpers
end
class String
  include Fancypath::Helpers
end
