$: << File.dirname(__FILE__)
require 'monkey_patches'
require 'dep'
require 'fakeistrano'


class Babushka
  def initialize argv
    @args = argv.dup
  end

  def load_deps
    Dir.glob('deps/**/*.rb').each {|f| require f }
    log "Loaded #{Dep.deps.count} dependencies."
  end

  def setup
    @targets = extract_args @args
    # if @targets.empty?
    #   exit_with "You have to specify the target machine on the commandline, e.g.:\n$ babushka you@target.machine.com"
    # end

    load_deps
    @setup = true
  end

  def run
    setup unless @setup
    # log "Running on #{@targets.to_list}."
    Dep('user setup').meet
    in_dir '../testapp' do
      Dep('migrated db').meet
    end
  end

  def exit_with message
    log message
    exit 1
  end


  private

  def extract_args args
    Cfg[:verbose_logging] = %w[-q --quiet].map {|arg| args.delete arg }.first.blank?
    Cfg[:debug] = args.delete('--debug')

    args
  end

end

def Babushka argv
  Babushka.new(argv).run
end

Babushka ARGV
