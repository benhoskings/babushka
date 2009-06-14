require 'monkey_patches'
require 'dep'
require 'fakeistrano'


# Dir.chdir RAILS_ROOT
# Dep('migrated db').meet

class Babushka

  def initialize argv
    @target_machine = argv[0]
  end

  def setup
    if @target_machine.blank?
      log_error "You have to specify the target machine on the commandline, e.g.:\n$ babushka you@target.machine.com"
    else
      @setup = true
    end
  end

  def load_deps
    Dir.glob('deps/**/*.rb').each {|f| require f }
    log "Loaded #{Dep.deps.count} dependencies."
    @deps_loaded = true
  end

  def setup?
    @setup && @deps_loaded
  end

  def run
    if setup?
      log "Running on #{@target_machine}."
    end
  end

end

def Babushka argv
  b = Babushka.new ARGV
  b.setup && b.load_deps
  b
end

Babushka(ARGV).run
