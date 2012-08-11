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

  alias_method :to_str, :to_s unless method_defined? :to_str

  alias_method :dir, :dirname
  alias_method :directory, :dirname

  alias_method :dir?, :directory?

  alias_method :expand, :expand_path
  alias_method :abs, :expand_path
  alias_method :absolute, :expand_path

  alias_method :exists?, :exist?
  alias_method :rename_to, :rename


  # About this Fancypath object.

  def inspect
    super.sub('Pathname','Fancypath')
  end

  def to_fancypath
    self
  end

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


  # Querying the path.

  def empty?
    directory? ? children.size == 0 : self.size == 0
  end

  def owner
    Etc.getpwuid(File.stat(to_s).uid).name
  end

  def group
    Etc.getgrgid(File.stat(to_s).gid).name
  end

  # True if the path is writable (and already exists), or createable by the
  # current user (i.e. if its closest existing parent is writable).
  def hypothetically_writable?
    writable? || (!exists? && !root? && parent.hypothetically_writable?)
  end


  # Path traversal & manipulation.

  def join(path)
    path_str = path.to_s
    super(path_str[0..0] == '/' ? path_str[1..-1] : path_str).p
  end
  alias_method :/, :join

  def parent
    super.p
  end

  def children
    super.reject { |c| c.basename.to_s =~ /^\./ }
  end
  alias_method :all_children, :children

  def readlink
    if !symlink?
      self
    elsif
      target = super
      target.absolute? ? target : (dir / target)
    end
  end


  # Querying the file the path refers to.

  def read
    super if exists?
  end

  def tail(bytes)
    return self.read if self.size < bytes
    open('r') do |f|
      f.seek(-bytes, IO::SEEK_END)
      f.read
    end
  end

  def yaml
    require 'yaml'
    YAML.load_file self
  end


  # Querying the tree below the dir the path refers to.

  def grep *args
    if exists?
      matches = read.split("\n").grep(*args)
      matches unless matches.empty?
    end
  end

  def glob expr = nil, flags = File::FNM_CASEFOLD, &block
    Dir.glob((expr.nil? ? self : (self / expr)).to_s, flags, &block)
  end

  def select(*args)
    Babushka::LogHelpers.deprecated! '2012-10-23', :instead => 'Fancypath#glob', :example => "#{to_s.inspect}.p.glob(#{args.first.inspect})"
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


  # Filename manupulation.

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


  # Changing the file or dir the path refers to.

  def touch
    `touch '#{self}'`
    self
  end

  def create_dir
    mkpath unless exist?
    self
  end
  alias_method :create, :create_dir
  alias_method :mkdir, :create_dir

  def copy(dest)
    `cp -pPR '#{self}' '#{dest}'`
    self
  end
  alias_method :cp, :copy

  def move(dest)
    self.rename(dest)
    dest.p
  end
  alias_method :mv, :move

  def remove
    directory? ? rmtree : delete if exist?
    self
  end
  alias_method :rm, :remove


  # Changing the contents of the file the path refers to.

  def write(contents, mode='wb')
    dirname.create
    open(mode) { |f| f.write contents }
    self
  end

  def append(contents)
    write(contents,'a+')
    self
  end

end

class Pathname
  include Fancypath::Helpers
end
class String
  include Fancypath::Helpers
end
