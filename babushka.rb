require 'rubygems'
require 'open4'

$log_indent = 0
RAILS_ROOT = '/Users/ben/projects/corkboard/current'
RAILS_ENV = 'production'

appname = 'corkboard'
dbname = 'corkboard'

Dir.chdir RAILS_ROOT

def returning obj, &block
  yield obj
  obj
end

def log message, &block
  print((' ' * $log_indent * 2) + message)
  if block_given?
    print " {\n"
    $log_indent += 1
    returning yield do
      $log_indent -= 1
      log "}"
    end
  else
    print "\n"
  end
end

class Object
  def in? list
    list.include? self
  end
end

class String
  # Returns true iff +str+ appears exactly at the start of +self+.
  def starts_with? str
    self[0, str.length] == str
  end

  # Returns true iff +str+ appears exactly at the end of +self+.
  def ends_with? str
    self[-str.length, str.length] == str
  end

  # Return a duplicate of +self+, with +str+ prepended to it if it doesn't already start with +str+.
  def start_with str
    starts_with?(str) ? self : str + self
  end

  # Return a duplicate of +self+, with +str+ appended to it if it doesn't already end with +str+.
  def end_with str
    ends_with?(str) ? self : self + str
  end

  def val_for key
    split("\n").grep(key).first.sub(/^#{key}\:?/).strip
  end
  def / other
    File.join self, other
  end
end

def yaml file_name
  require 'yaml'
  YAML::load_file(RAILS_ROOT / file_name)
end

def shell cmd
  log "running '#{cmd}'"
  _stdout, _stderr = nil, nil
  status = Open4.popen4 cmd do |pid,stdin,stdout,stderr|
    _stdout, _stderr = stdout.read, stderr.read
  end
  returning (status.exitstatus == 0 ? _stdout : false) do |result|
    log "failed with '#{_stderr.chomp}'" unless result
  end
end

def sudo cmd
  log "(would be sudoing the next command)"
  shell cmd
end

def rake cmd
  shell "rake #{cmd}"
end

class PkgManager
  def self.for_system
    case `uname -s`.chomp
    when 'Darwin'; MacportsHelper
    when 'Linux'; AptHelper
    end.new
  end
end

class MacportsHelper < PkgManager
  def has? pkg_name
    returning pkg_name.in? existing_packages do |result|
      log "system #{result ? 'has' : 'doesn\'t have'} #{pkg_name} port"
    end
  end
  def install! *pkgs
    shell "port install #{pkgs.join(' ')}"
  end
  def existing_packages
    Dir.glob("/opt/local/var/macports/software/*").map {|i| File.basename i }
  end
  def cmd_dir cmd_name
    File.dirname shell("which #{cmd_name}")
  end
  def prefix
    cmd_dir('port').sub(/\/bin\/?$/, '')
  end
  def bin_path
    prefix / 'bin'
  end
  def cmd_in_path? cmd_name
    returning cmd_dir(cmd_name).starts_with?(prefix) do |result|
      log "#{result ? 'the correct' : 'an incorrect installation of'} #{cmd_name} is in use, at #{cmd_dir(cmd_name)}."
    end
  end
end
class AptHelper < PkgManager
  def self.has? pkg_name
    returning shell "dpkg -s #{pkg_name}" do |result|
      log "system #{result ? 'has' : 'doesn\'t have'} #{pkg_name} package"
    end
  end
  def self.install! *pkgs
    shell "apt-get install #{pkgs.join(' ')}"
  end
end
class GemHelper < PkgManager
  def self.has? pkg_name
    returning shell "gem list -i #{pkg_name}" do |result|
      log "system #{result ? 'has' : 'doesn\'t have'} #{pkg_name} gem"
    end
  end
  def self.install! *pkgs
    sudo "gem install #{pkgs.join(' ')}"
  end
end


def pkg_manager
  PkgManager.for_system
end

class DepDefiner
  def initialize &block
    @defines = {:requires => []}
    instance_eval &block
  end
  def requires *deps
    @defines[:requires] = deps
  end
  def met? &block
    @defines[:met?] = block
  end
  def meet &block
    @defines[:meet] = block
  end

  # def self.block_writer name
  #   define_method name do |&block|
  #     instance_variable_set name, block
  #   end
  # end
  def self.attr_setter *names
    names.each {|name|
      define_method name do |obj|
        instance_variable_set "@#{name}", obj
      end
    }
  end

  def payload
    {
      :requires => @defines[:requires],
      :met? => @defines[:met?],
      :meet => @defines[:meet]
    }
  end
end

class PkgDepDefiner < DepDefiner

  attr_setter :pkg, :provides

  def payload
    super.merge({
      :met? => lambda {
        @pkg[:macports].all? {|pkg_name| pkg_manager.has?(pkg_name) } &&
        @provides.all? {|cmd_name|
          pkg_manager.cmd_in_path? cmd_name
        }
      },
      :meet => lambda {
        'lol'
      }
    })
  end

end

class GemDepDefiner < DepDefiner

  attr_setter :pkg

  def payload
    super.merge({
      :met? => lambda {
        @pkg.all? {|pkg_name| GemHelper.has?(pkg_name) }
      },
      :meet => lambda {
        'lol'
      }
    })
  end

end

class Dep
  attr_reader :name
  
  def initialize name, block, definer_class = DepDefiner
    @name = name
    @defines = definer_class.new(&block).payload
    [:requires, :met?, :meet].each {|item|
      raise "You need to specify '#{item}' in the dep \"#{name}\" definition." if @defines[item].nil?
    }
    # log "Dep #{name} depends on #{@defines[:requires].inspect}"
    Dep.register self
  end

  def self.register dep
    @@deps ||= {}
    raise "There is already a registered dep called '#{dep.name}'." unless @@deps[dep.name].nil?
    @@deps[dep.name] = dep
  end
  def self.for name
    @@deps[name]
  end
  
  def dep_task method_name
    @defines[:requires].all? {|requirement|
      if (dep = Dep.for(requirement)).nil?
        raise "dep '#{name}' requires '#{requirement}', which doesn't exist."
      else
        dep.send method_name
      end
    }
  end

  def met?
    @cached_met ||= dep_task(:met?) && @defines[:met?].call
  end
  
  def meet
    log "#{name}..." do
      # begin
        dep_task(:meet) && (met? || @defines[:meet].call)
      # rescue Exception => e
      #   log "Tried to install #{@name}, and #{e.to_s} out of fucking nowhere."
      #   log e.backtrace.inspect
      #   false
      # end
    end
  end
end

def dep name, &block
  Dep.new name, block
end

def pkg_dep name, &block
  Dep.new name, block, PkgDepDefiner
end
def gem_dep name, &block
  Dep.new name, block, GemDepDefiner
end
dep 'migrated db' do
  requires 'db access', 'existing db'
  met? { shell "rake db:version".val_for('Current version') == Dir.glob('db/migrate').sort.last.split('_', 2).first }
  meet { rake "db:migrate --trace" }
end

dep 'existing db' do
  requires 'db gem', 'db access'
  met? { shell("rake db:create")['already exists'] }
  meet { rake "db:create" }
end

gem_dep 'db gem' do
  requires 'db software'
  pkg 'pg'
  # gem_dep({
  #   'mysql' => 'mysql',
  #   'postgresql' => 'pg',
  #   'sqlite3' => 'sqlite3'
  # }[yaml('config/database.yml')[RAILS_ENV]['adapter']])
end

dep 'db access' do
  requires 'db software'
  met? { shell "echo '\\d' | psql #{dbname}" }
  meet { sudo "createuser #{appname}" }
end

pkg_dep 'db software' do
  pkg :macports => 'postgresql83-server', :apt => 'postgresql-8.2'
  provides 'psql'
  # provides({
  #   'mysql' => AptPkg.new('mysql-server', 'mysql5'),
  #   'postgresql' => AptPkg.new('postgresql-8.2', 'psql'),
  #   'sqlite3' => 'sqlite3'
  # }[yaml('config/database.yml')[RAILS_ENV]['adapter']])
end

Dep.for('migrated db').meet
