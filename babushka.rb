$: << File.dirname(__FILE__)
require 'monkey_patches'
require 'dep'
require 'fakeistrano'


class Babushka

  def initialize argv
    @target_machine = argv[0]
  end

  def setup
    if @target_machine.blank?
      log "You have to specify the target machine on the commandline, e.g.:\n$ babushka you@target.machine.com"
    else
      @setup = true
    end
    self
  end

  def load_deps
    if @setup
      Dir.glob('deps/**/*.rb').each {|f| require f }
      log "Loaded #{Dep.deps.count} dependencies."
      @deps_loaded = true
    end
    self
  end

  def setup?
    @setup && @deps_loaded
  end

  def run
    if setup?
      log "Running on #{@target_machine}."
      in_dir '../testapp' do
        Dep('migrated db').meet
      end
    end
  end

end

def Babushka argv
  Babushka.new(ARGV).setup.load_deps
end

Babushka(ARGV).run
